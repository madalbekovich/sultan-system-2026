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
    planned_qty: Decimal
    actual_qty: Decimal | None
    final_price: Decimal | None

    model_config = {"from_attributes": True}


class OrderRead(BaseModel):
    id: int
    client_id: int
    created_at: datetime
    delivery_date: date
    status: OrderStatus
    total_amount: Decimal
    items: list[OrderItemRead] = []

    model_config = {"from_attributes": True}


class WeightUpdateRequest(BaseModel):
    actual_qty: Decimal


class ProductSummaryEntry(BaseModel):
    product_id: int
    product_name: str
    unit_type: str
    total_planned_qty: Decimal
    client_count: int


class OrdersSummaryResponse(BaseModel):
    delivery_date: date
    products: list[ProductSummaryEntry]
