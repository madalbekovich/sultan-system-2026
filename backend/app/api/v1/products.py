from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.api.deps import get_current_username, get_db, require_bot_or_manager
from app.models.product import Product
from app.schemas.product import PriceCoverageRead, ProductCreate, ProductRead, ProductUpdate
from app.services.client_pricing import get_client_price_overrides, get_price_coverage

router = APIRouter(prefix="/products", tags=["products"])


def _to_product_read(product: Product, effective_price) -> ProductRead:
    return ProductRead(
        id=product.id,
        category_id=product.category_id,
        name=product.name,
        unit_type=product.unit_type,
        price_per_unit=effective_price,
        is_active=product.is_active,
        weight_grams=product.weight_grams,
    )


@router.get("/", response_model=list[ProductRead], dependencies=[Depends(require_bot_or_manager)])
async def list_products(
    active_only: bool = True,
    category_id: int | None = None,
    client_id: int | None = None,
    db: AsyncSession = Depends(get_db),
) -> list[ProductRead]:
    """Base catalog. With `client_id` (bot-only in practice — the caller
    must already hold the bot key to reach this endpoint at all), prices
    are resolved to that client's own price sheet instead of the base
    price. Without it, prices are always the base price — used by the
    manager app's general catalog screen."""
    query = select(Product)
    if active_only:
        query = query.where(Product.is_active == True)  # noqa: E712
    if category_id is not None:
        query = query.where(Product.category_id == category_id)
    products = list((await db.execute(query)).scalars().all())
    if not products:
        return []

    overrides = (
        await get_client_price_overrides(db, client_id, [p.id for p in products])
        if client_id is not None
        else {}
    )
    return [
        _to_product_read(p, overrides.get(p.id, p.price_per_unit))
        for p in products
    ]


@router.get(
    "/price-coverage",
    response_model=list[PriceCoverageRead],
    dependencies=[Depends(get_current_username)],
)
async def price_coverage(db: AsyncSession = Depends(get_db)) -> list[PriceCoverageRead]:
    """Per product: how many warehouses have their own price vs. are
    falling back to base — drives the "у N складов нет цены" indicator."""
    entries = await get_price_coverage(db)
    return [
        PriceCoverageRead(
            product_id=e.product_id,
            product_name=e.product_name,
            clients_total=e.clients_total,
            clients_with_own_price=e.clients_with_own_price,
            clients_missing=e.clients_missing,
        )
        for e in entries
    ]


@router.post("/", response_model=ProductRead, dependencies=[Depends(get_current_username)])
async def create_product(payload: ProductCreate, db: AsyncSession = Depends(get_db)) -> ProductRead:
    product = Product(**payload.model_dump())
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return _to_product_read(product, product.price_per_unit)


@router.patch(
    "/{product_id}", response_model=ProductRead, dependencies=[Depends(get_current_username)]
)
async def update_product(
    product_id: int, payload: ProductUpdate, db: AsyncSession = Depends(get_db)
) -> ProductRead:
    product = await db.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return _to_product_read(product, product.price_per_unit)
