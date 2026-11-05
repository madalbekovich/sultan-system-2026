from dataclasses import dataclass
from decimal import Decimal, InvalidOperation

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.client import Client
from app.models.client_product_price import ClientProductPrice
from app.models.price_change_log import PriceChangeLog
from app.models.product import Product


async def get_client_price_overrides(
    db: AsyncSession, client_id: int, product_ids: list[int]
) -> dict[int, Decimal]:
    """product_id -> this client's own price, for whichever of the given
    products they actually have one. Products with no row here use the
    base `products.price_per_unit` — callers fall back to that themselves."""
    if not product_ids:
        return {}
    stmt = select(ClientProductPrice.product_id, ClientProductPrice.price_per_unit).where(
        ClientProductPrice.client_id == client_id,
        ClientProductPrice.product_id.in_(product_ids),
    )
    rows = (await db.execute(stmt)).all()
    return {row.product_id: row.price_per_unit for row in rows}


async def _log_change(
    db: AsyncSession,
    client_id: int,
    product_id: int,
    old_price: Decimal | None,
    new_price: Decimal | None,
    changed_by: str,
    source: str,
) -> None:
    db.add(
        PriceChangeLog(
            client_id=client_id,
            product_id=product_id,
            old_price=old_price,
            new_price=new_price,
            changed_by=changed_by,
            source=source,
        )
    )


async def set_client_price(
    db: AsyncSession,
    client_id: int,
    product_id: int,
    price: Decimal | None,
    changed_by: str,
    source: str = "manual",
) -> None:
    """price=None clears the override (client falls back to base price);
    otherwise inserts or updates it. Writes an audit-log row either way,
    skipped only if the value didn't actually change."""
    existing = (
        await db.execute(
            select(ClientProductPrice).where(
                ClientProductPrice.client_id == client_id,
                ClientProductPrice.product_id == product_id,
            )
        )
    ).scalar_one_or_none()

    old_price = existing.price_per_unit if existing else None
    if old_price == price:
        return

    if price is None:
        if existing is not None:
            await db.delete(existing)
    elif existing is not None:
        existing.price_per_unit = price
        db.add(existing)
    else:
        db.add(ClientProductPrice(client_id=client_id, product_id=product_id, price_per_unit=price))

    await _log_change(db, client_id, product_id, old_price, price, changed_by, source)


@dataclass
class PriceSheetRow:
    product_id: int
    product_name: str
    unit_type: str
    base_price: Decimal
    own_price: Decimal | None

    @property
    def has_own_price(self) -> bool:
        return self.own_price is not None


async def get_price_sheet(db: AsyncSession, client_id: int) -> list[PriceSheetRow]:
    """Every active product with this client's own price if set, else the
    base price — the source of truth for both the app's price editor and
    the Excel export template (which must be pre-filled, not blank)."""
    products = (
        await db.execute(select(Product).where(Product.is_active == True))  # noqa: E712
    ).scalars().all()
    overrides = await get_client_price_overrides(db, client_id, [p.id for p in products])
    return [
        PriceSheetRow(
            product_id=p.id,
            product_name=p.name,
            unit_type=p.unit_type.value if hasattr(p.unit_type, "value") else p.unit_type,
            base_price=p.price_per_unit,
            own_price=overrides.get(p.id),
        )
        for p in sorted(products, key=lambda p: p.name)
    ]


@dataclass
class PriceSheetImportError:
    row: int
    product_id: int | None
    message: str


@dataclass
class PriceSheetImportResult:
    ok: bool
    updated: int = 0
    cleared: int = 0
    errors: list[PriceSheetImportError] | None = None


async def validate_and_apply_price_sheet(
    db: AsyncSession,
    client_id: int,
    rows: list[dict],
    changed_by: str,
) -> PriceSheetImportResult:
    """rows: [{row, product_id, price}] (1-indexed `row` for error
    messages; `price` is a string, or null/empty to clear the override).
    Validates every row first — a single bad row rejects the whole import,
    nothing is written. Only on full success are changes applied and
    logged, in one transaction."""
    client = await db.get(Client, client_id)
    if client is None:
        return PriceSheetImportResult(
            ok=False, errors=[PriceSheetImportError(row=0, product_id=None, message="Склад не найден")]
        )

    product_ids = [r["product_id"] for r in rows if r.get("product_id") is not None]
    existing_products = {
        p.id
        for p in (
            await db.execute(select(Product.id).where(Product.id.in_(product_ids)))
        ).all()
    }

    errors: list[PriceSheetImportError] = []
    parsed: list[tuple[int, Decimal | None]] = []
    seen_products: set[int] = set()

    for r in rows:
        row_num = r.get("row")
        product_id = r.get("product_id")
        raw_price = r.get("price")

        if product_id is None:
            errors.append(PriceSheetImportError(row=row_num, product_id=None, message="Не указан товар"))
            continue
        if product_id not in existing_products:
            errors.append(
                PriceSheetImportError(row=row_num, product_id=product_id, message="Товар не найден")
            )
            continue
        if product_id in seen_products:
            errors.append(
                PriceSheetImportError(row=row_num, product_id=product_id, message="Товар повторяется в таблице")
            )
            continue
        seen_products.add(product_id)

        if raw_price is None or str(raw_price).strip() == "":
            parsed.append((product_id, None))
            continue

        try:
            price = Decimal(str(raw_price).strip().replace(",", "."))
        except InvalidOperation:
            errors.append(
                PriceSheetImportError(row=row_num, product_id=product_id, message="Цена не число")
            )
            continue
        if price < 0:
            errors.append(
                PriceSheetImportError(row=row_num, product_id=product_id, message="Цена отрицательная")
            )
            continue
        parsed.append((product_id, price))

    if errors:
        return PriceSheetImportResult(ok=False, errors=errors)

    updated = 0
    cleared = 0
    for product_id, price in parsed:
        before = await get_client_price_overrides(db, client_id, [product_id])
        await set_client_price(db, client_id, product_id, price, changed_by, source="excel_import")
        if price is None and product_id in before:
            cleared += 1
        elif price is not None:
            updated += 1

    await db.commit()
    return PriceSheetImportResult(ok=True, updated=updated, cleared=cleared)


async def copy_prices(
    db: AsyncSession, source_client_id: int, target_client_id: int, changed_by: str
) -> int:
    """Bulk-copies every price row the source client has onto the target
    client (overwriting any the target already has for the same
    products) — the "start from another warehouse's sheet" convenience
    when onboarding a new one. Returns how many rows were copied."""
    source_rows = (
        await db.execute(
            select(ClientProductPrice.product_id, ClientProductPrice.price_per_unit).where(
                ClientProductPrice.client_id == source_client_id
            )
        )
    ).all()
    for row in source_rows:
        await set_client_price(
            db, target_client_id, row.product_id, row.price_per_unit, changed_by, source="copy_from_client"
        )
    await db.commit()
    return len(source_rows)


@dataclass
class PriceCoverageEntry:
    product_id: int
    product_name: str
    clients_total: int
    clients_with_own_price: int

    @property
    def clients_missing(self) -> int:
        return self.clients_total - self.clients_with_own_price


async def get_price_coverage(db: AsyncSession) -> list[PriceCoverageEntry]:
    """Per active product: how many (non-archived) clients have their own
    price set vs. are falling back to base — drives the "у N складов нет
    своей цены" indicator/filter in the catalog screen."""
    clients_total = (
        await db.execute(
            select(func.count(Client.id)).where(Client.is_archived == False)  # noqa: E712
        )
    ).scalar_one()

    products = (
        await db.execute(select(Product).where(Product.is_active == True))  # noqa: E712
    ).scalars().all()

    counts_stmt = (
        select(ClientProductPrice.product_id, func.count(ClientProductPrice.id))
        .join(Client, Client.id == ClientProductPrice.client_id)
        .where(Client.is_archived == False)  # noqa: E712
        .group_by(ClientProductPrice.product_id)
    )
    counts = dict((await db.execute(counts_stmt)).all())

    return [
        PriceCoverageEntry(
            product_id=p.id,
            product_name=p.name,
            clients_total=clients_total,
            clients_with_own_price=counts.get(p.id, 0),
        )
        for p in products
    ]
