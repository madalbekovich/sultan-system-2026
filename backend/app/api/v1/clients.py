from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.api.deps import get_current_username, get_db
from app.models.client import Client
from app.schemas.client import ClientRead, ClientRegister

router = APIRouter(prefix="/clients", tags=["clients"])


@router.get("/", response_model=list[ClientRead], dependencies=[Depends(get_current_username)])
async def list_clients(db: AsyncSession = Depends(get_db)) -> list[Client]:
    result = await db.execute(select(Client).order_by(Client.name))
    return list(result.scalars().all())


@router.post("/register", response_model=ClientRead)
async def register_client(payload: ClientRegister, db: AsyncSession = Depends(get_db)) -> Client:
    """Get-or-create a client by Telegram user id, used by the bot on /start and checkout."""
    result = await db.execute(select(Client).where(Client.tg_user_id == payload.tg_user_id))
    client = result.scalar_one_or_none()

    if client is None:
        client = Client(**payload.model_dump())
    else:
        client.name = payload.name
        if payload.phone is not None:
            client.phone = payload.phone
        if payload.address is not None:
            client.address = payload.address

    db.add(client)
    await db.commit()
    await db.refresh(client)
    return client


@router.get("/by-tg/{tg_user_id}", response_model=ClientRead)
async def get_client_by_tg_id(tg_user_id: int, db: AsyncSession = Depends(get_db)) -> Client:
    result = await db.execute(select(Client).where(Client.tg_user_id == tg_user_id))
    client = result.scalar_one_or_none()
    if client is None:
        raise HTTPException(status_code=404, detail="Client not found")
    return client
