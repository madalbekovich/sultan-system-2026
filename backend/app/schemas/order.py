from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel

from app.models.order import OrderStatus


class OrderItemCreate(BaseModel):
    product_id: int
    planned_qty: Decimal


class OrderCreate(BaseModel):
    client_id: int
    delivery_date: date
    items: list[OrderItemCreate]


class OrderItemRead(BaseModel):
    id: int
    product_id: int
    product_name: str
    unit_type: str
    planned_qty: Decimal
    actual_qty: Decimal | None
    final_price: Decimal | None

    model_config = {"from_attributes": True}


class OrderRead(BaseModel):
    id: int
    client_id: int
    client_name: str
    client_code: str | None = None
    # The client's *current* region — historical display only, kept for
    # orders placed before the region-pricing model was retired.
    client_region: str | None = None
    created_at: datetime
    delivery_date: date
    status: OrderStatus
    total_amount: Decimal
    total_weight_grams: Decimal
    items: list[OrderItemRead] = []

    model_config = {"from_attributes": True}


class WeightUpdateRequest(BaseModel):
    actual_qty: Decimal


class OrderStatusUpdateRequest(BaseModel):
    status: OrderStatus


class ProductSummaryEntry(BaseModel):
    product_id: int
    product_name: str
    unit_type: str
    total_planned_qty: Decimal
    total_weight_grams: Decimal
    client_count: int


class OrdersSummaryResponse(BaseModel):
    delivery_date: date
    order_count: int
    products: list[ProductSummaryEntry]


class DailySalesEntry(BaseModel):
    delivery_date: date
    total_amount: Decimal
    order_count: int


class DashboardAnalytics(BaseModel):
    daily_sales: list[DailySalesEntry]
    top_products: list[ProductSummaryEntry]
    recent_orders: list[OrderRead]
