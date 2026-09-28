from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.api.deps import get_current_username, get_db
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductRead, ProductUpdate

router = APIRouter(prefix="/products", tags=["products"])


@router.get("/", response_model=list[ProductRead])
async def list_products(
    active_only: bool = True,
    category_id: int | None = None,
    db: AsyncSession = Depends(get_db),
) -> list[Product]:
    query = select(Product)
    if active_only:
        query = query.where(Product.is_active == True)  # noqa: E712
    if category_id is not None:
        query = query.where(Product.category_id == category_id)
    result = await db.execute(query)
    return list(result.scalars().all())


@router.post("/", response_model=ProductRead, dependencies=[Depends(get_current_username)])
async def create_product(payload: ProductCreate, db: AsyncSession = Depends(get_db)) -> Product:
    product = Product(**payload.model_dump())
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product


@router.patch(
    "/{product_id}", response_model=ProductRead, dependencies=[Depends(get_current_username)]
)
async def update_product(
    product_id: int, payload: ProductUpdate, db: AsyncSession = Depends(get_db)
) -> Product:
    product = await db.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product
