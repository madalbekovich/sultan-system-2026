from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.api.deps import get_current_username, get_db, require_bot_or_manager
from app.models.client import Client
from app.schemas.client import (
    ClientBindRequest,
    ClientCreate,
    ClientRead,
    ClientUpdate,
    CopyPricesRequest,
    PriceSheetImportResultRead,
    PriceSheetImportRow,
    PriceSheetRowRead,
)
from app.services.client_pricing import copy_prices, get_price_sheet, validate_and_apply_price_sheet

router = APIRouter(prefix="/clients", tags=["clients"])


def _to_client_read(client: Client) -> ClientRead:
    return ClientRead(
        id=client.id,
        client_code=client.client_code,
        tg_user_id=client.tg_user_id,
        name=client.name,
        phone=client.phone,
        address=client.address,
        is_archived=client.is_archived,
        is_bound=client.tg_user_id is not None,
    )


async def _get_client_or_404(db: AsyncSession, client_id: int) -> Client:
    client = await db.get(Client, client_id)
    if client is None:
        raise HTTPException(status_code=404, detail="Client not found")
    return client


async def _next_client_code(db: AsyncSession) -> str:
    result = await db.execute(text("SELECT nextval('client_code_seq')"))
    n = result.scalar_one()
    return f"SC-{n:04d}"


@router.get("/", response_model=list[ClientRead], dependencies=[Depends(get_current_username)])
async def list_clients(
    include_archived: bool = False, db: AsyncSession = Depends(get_db)
) -> list[ClientRead]:
    stmt = select(Client).order_by(Client.name)
    if not include_archived:
        stmt = stmt.where(Client.is_archived == False)  # noqa: E712
    result = await db.execute(stmt)
    return [_to_client_read(c) for c in result.scalars().all()]


@router.post("/", response_model=ClientRead, dependencies=[Depends(get_current_username)])
async def create_client(
    payload: ClientCreate, username: str = Depends(get_current_username), db: AsyncSession = Depends(get_db)
) -> ClientRead:
    """Manager-only — clients/warehouses are never self-registered any
    more. tg_user_id stays null until the warehouse's own person binds
    their Telegram account with the code (POST /clients/bind)."""
    code = await _next_client_code(db)
    client = Client(name=payload.name, phone=payload.phone, address=payload.address, client_code=code)
    db.add(client)
    await db.commit()
    await db.refresh(client)

    if payload.copy_prices_from_client_id is not None:
        await copy_prices(db, payload.copy_prices_from_client_id, client.id, username)

    return _to_client_read(client)


@router.patch("/{client_id}", response_model=ClientRead, dependencies=[Depends(get_current_username)])
async def update_client(
    client_id: int, payload: ClientUpdate, db: AsyncSession = Depends(get_db)
) -> ClientRead:
    client = await _get_client_or_404(db, client_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(client, field, value)
    db.add(client)
    await db.commit()
    await db.refresh(client)
    return _to_client_read(client)


@router.patch(
    "/{client_id}/unbind", response_model=ClientRead, dependencies=[Depends(get_current_username)]
)
async def unbind_client(client_id: int, db: AsyncSession = Depends(get_db)) -> ClientRead:
    """Manager-only — clears the Telegram binding so the warehouse's code
    can be entered again from a different account (lost phone, staff
    change, etc.)."""
    client = await _get_client_or_404(db, client_id)
    client.tg_user_id = None
    db.add(client)
    await db.commit()
    await db.refresh(client)
    return _to_client_read(client)


@router.post("/bind", response_model=ClientRead, dependencies=[Depends(require_bot_or_manager)])
async def bind_client(payload: ClientBindRequest, db: AsyncSession = Depends(get_db)) -> ClientRead:
    """Bot-only — the one-shot "enter your warehouse code" step. A code
    already bound to a different Telegram account is rejected; binding it
    again from the SAME account is a harmless no-op (handles re-sending
    /start with the same code)."""
    result = await db.execute(select(Client).where(Client.client_code == payload.code))
    client = result.scalar_one_or_none()
    if client is None:
        raise HTTPException(status_code=404, detail="Код не найден")
    if client.tg_user_id is not None and client.tg_user_id != payload.tg_user_id:
        raise HTTPException(status_code=409, detail="Код уже привязан к другому аккаунту")

    if client.tg_user_id is None:
        client.tg_user_id = payload.tg_user_id
        db.add(client)
        await db.commit()
        await db.refresh(client)
    return _to_client_read(client)


@router.get(
    "/by-tg/{tg_user_id}", response_model=ClientRead, dependencies=[Depends(require_bot_or_manager)]
)
async def get_client_by_tg_id(tg_user_id: int, db: AsyncSession = Depends(get_db)) -> ClientRead:
    result = await db.execute(select(Client).where(Client.tg_user_id == tg_user_id))
    client = result.scalar_one_or_none()
    if client is None:
        raise HTTPException(status_code=404, detail="Client not found")
    return _to_client_read(client)


@router.get(
    "/{client_id}/price-sheet",
    response_model=list[PriceSheetRowRead],
    dependencies=[Depends(get_current_username)],
)
async def client_price_sheet(client_id: int, db: AsyncSession = Depends(get_db)) -> list[PriceSheetRowRead]:
    await _get_client_or_404(db, client_id)
    rows = await get_price_sheet(db, client_id)
    return [
        PriceSheetRowRead(
            product_id=r.product_id,
            product_name=r.product_name,
            unit_type=r.unit_type,
            base_price=r.base_price,
            own_price=r.own_price,
            has_own_price=r.has_own_price,
        )
        for r in rows
    ]


@router.post(
    "/{client_id}/price-sheet/import",
    response_model=PriceSheetImportResultRead,
    dependencies=[Depends(get_current_username)],
)
async def import_client_price_sheet(
    client_id: int,
    rows: list[PriceSheetImportRow],
    username: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
) -> PriceSheetImportResultRead:
    result = await validate_and_apply_price_sheet(
        db, client_id, [r.model_dump() for r in rows], username
    )
    return PriceSheetImportResultRead(
        ok=result.ok,
        updated=result.updated,
        cleared=result.cleared,
        errors=[
            {"row": e.row, "product_id": e.product_id, "message": e.message}
            for e in (result.errors or [])
        ],
    )


@router.post(
    "/{client_id}/copy-prices", response_model=ClientRead, dependencies=[Depends(get_current_username)]
)
async def copy_prices_to_client(
    client_id: int,
    payload: CopyPricesRequest,
    username: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
) -> ClientRead:
    client = await _get_client_or_404(db, client_id)
    await copy_prices(db, payload.source_client_id, client_id, username)
    return _to_client_read(client)
