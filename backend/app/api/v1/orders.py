from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.api.deps import get_current_username, get_db
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.product import Product
from app.schemas.order import (
    OrderCreate,
    OrderRead,
    OrdersSummaryResponse,
    WeightUpdateRequest,
)
from app.services.pdf import render_waybill_pdf
from app.services.summary import get_orders_summary, invalidate_summary_cache

router = APIRouter(prefix="/orders", tags=["orders"])


@router.get("/summary", response_model=OrdersSummaryResponse)
async def orders_summary(
    delivery_date: date | None = None, db: AsyncSession = Depends(get_db)
) -> OrdersSummaryResponse:
    target_date = delivery_date or date.today()
    return await get_orders_summary(db, target_date)


@router.post("/", response_model=OrderRead)
async def create_order(payload: OrderCreate, db: AsyncSession = Depends(get_db)) -> Order:
    product_ids = [item.product_id for item in payload.items]
    products = (
        (await db.execute(select(Product).where(Product.id.in_(product_ids))))
        .scalars()
        .all()
    )
    price_by_id = {p.id: p.price_per_unit for p in products}
    if len(price_by_id) != len(set(product_ids)):
        raise HTTPException(status_code=400, detail="One or more products not found")

    order = Order(client_id=payload.client_id, delivery_date=payload.delivery_date)
    total = 0
    for item in payload.items:
        line_total = price_by_id[item.product_id] * item.planned_qty
        total += line_total
        order.items.append(
            OrderItem(
                product_id=item.product_id,
                planned_qty=item.planned_qty,
                final_price=line_total,
            )
        )
    order.total_amount = total

    db.add(order)
    await db.commit()
    await db.refresh(order, attribute_names=["items"])
    await invalidate_summary_cache(payload.delivery_date)
    return order


@router.patch(
    "/items/{item_id}/weight",
    response_model=OrderRead,
    dependencies=[Depends(get_current_username)],
)
async def update_item_weight(
    item_id: int, payload: WeightUpdateRequest, db: AsyncSession = Depends(get_db)
) -> Order:
    order_item = await db.get(OrderItem, item_id)
    if order_item is None:
        raise HTTPException(status_code=404, detail="Order item not found")

    order_item.actual_qty = payload.actual_qty
    db.add(order_item)
    await db.commit()

    order = await db.get(Order, order_item.order_id)
    await db.refresh(order, attribute_names=["items"])
    await invalidate_summary_cache(order.delivery_date)
    return order


@router.get(
    "/{order_id}/waybill-pdf", dependencies=[Depends(get_current_username)]
)
async def waybill_pdf(order_id: int, db: AsyncSession = Depends(get_db)) -> Response:
    stmt = (
        select(Order)
        .where(Order.id == order_id)
        .options(selectinload(Order.items).selectinload(OrderItem.product), selectinload(Order.client))
    )
    order = (await db.execute(stmt)).scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    pdf_bytes = render_waybill_pdf(order, order.client)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="waybill-{order_id}.pdf"'},
    )
