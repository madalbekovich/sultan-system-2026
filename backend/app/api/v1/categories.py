from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.api.deps import get_db
from app.models.category import Category
from app.schemas.category import CategoryRead

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("/", response_model=list[CategoryRead])
async def list_categories(db: AsyncSession = Depends(get_db)) -> list[Category]:
    result = await db.execute(select(Category).order_by(Category.name))
    return list(result.scalars().all())
