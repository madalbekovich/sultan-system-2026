import json
from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.redis import redis_client
from app.models.order import Order, OrderStatus
from app.models.order_item import OrderItem
from app.models.product import Product
from app.schemas.order import OrdersSummaryResponse, ProductSummaryEntry

SUMMARY_CACHE_TTL_SECONDS = 15


def _cache_key(delivery_date: date) -> str:
    return f"orders:summary:{delivery_date.isoformat()}"


async def get_orders_summary(db: AsyncSession, delivery_date: date) -> OrdersSummaryResponse:
    cache_key = _cache_key(delivery_date)
    cached = await redis_client.get(cache_key)
    if cached is not None:
        return OrdersSummaryResponse.model_validate(json.loads(cached))

    stmt = (
        select(
            Product.id,
            Product.name,
            Product.unit_type,
            func.sum(OrderItem.planned_qty).label("total_planned_qty"),
            func.count(func.distinct(Order.client_id)).label("client_count"),
        )
        .join(OrderItem, OrderItem.product_id == Product.id)
        .join(Order, Order.id == OrderItem.order_id)
        .where(
            Order.delivery_date == delivery_date,
            Order.status != OrderStatus.DISPATCHED,
        )
        .group_by(Product.id, Product.name, Product.unit_type)
        .order_by(Product.name)
    )
    rows = (await db.execute(stmt)).all()

    products = [
        ProductSummaryEntry(
            product_id=row.id,
            product_name=row.name,
            unit_type=row.unit_type.value if hasattr(row.unit_type, "value") else row.unit_type,
            total_planned_qty=Decimal(row.total_planned_qty or 0),
            client_count=row.client_count,
        )
        for row in rows
    ]
    response = OrdersSummaryResponse(delivery_date=delivery_date, products=products)

    await redis_client.set(
        cache_key, response.model_dump_json(), ex=SUMMARY_CACHE_TTL_SECONDS
    )
    return response


async def invalidate_summary_cache(delivery_date: date) -> None:
    await redis_client.delete(_cache_key(delivery_date))
