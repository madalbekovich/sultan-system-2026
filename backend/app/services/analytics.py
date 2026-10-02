from datetime import date, timedelta
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.product import Product
from app.schemas.order import DailySalesEntry, DashboardAnalytics, ProductSummaryEntry
from app.services.orders import to_order_read


async def get_dashboard_analytics(
    db: AsyncSession, days: int = 7, recent_limit: int = 6
) -> DashboardAnalytics:
    today = date.today()
    start_date = today - timedelta(days=days - 1)

    sales_stmt = (
        select(
            Order.delivery_date,
            func.coalesce(func.sum(Order.total_amount), 0).label("total_amount"),
            func.count(Order.id).label("order_count"),
        )
        .where(Order.delivery_date >= start_date, Order.delivery_date <= today)
        .group_by(Order.delivery_date)
    )
    sales_rows = {row.delivery_date: row for row in (await db.execute(sales_stmt)).all()}

    daily_sales = [
        DailySalesEntry(
            delivery_date=day,
            total_amount=Decimal(sales_rows[day].total_amount) if day in sales_rows else Decimal("0"),
            order_count=sales_rows[day].order_count if day in sales_rows else 0,
        )
        for day in (start_date + timedelta(days=i) for i in range(days))
    ]

    top_products_stmt = (
        select(
            Product.id,
            Product.name,
            Product.unit_type,
            func.sum(OrderItem.planned_qty).label("total_planned_qty"),
            func.count(func.distinct(Order.client_id)).label("client_count"),
        )
        .join(OrderItem, OrderItem.product_id == Product.id)
        .join(Order, Order.id == OrderItem.order_id)
        .where(Order.delivery_date >= start_date, Order.delivery_date <= today)
        .group_by(Product.id, Product.name, Product.unit_type)
        .order_by(func.sum(OrderItem.planned_qty).desc())
        .limit(5)
    )
    top_rows = (await db.execute(top_products_stmt)).all()
    top_products = [
        ProductSummaryEntry(
            product_id=row.id,
            product_name=row.name,
            unit_type=row.unit_type.value if hasattr(row.unit_type, "value") else row.unit_type,
            total_planned_qty=Decimal(row.total_planned_qty or 0),
            client_count=row.client_count,
        )
        for row in top_rows
    ]

    recent_stmt = (
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product),
            selectinload(Order.client),
        )
        .order_by(Order.created_at.desc())
        .limit(recent_limit)
    )
    recent_orders = (await db.execute(recent_stmt)).scalars().all()

    return DashboardAnalytics(
        daily_sales=daily_sales,
        top_products=top_products,
        recent_orders=[to_order_read(order) for order in recent_orders],
    )
