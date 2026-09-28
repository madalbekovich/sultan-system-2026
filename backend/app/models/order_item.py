from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlmodel import Field, Relationship, SQLModel

if TYPE_CHECKING:
    from app.models.order import Order
    from app.models.product import Product


class OrderItem(SQLModel, table=True):
    __tablename__ = "order_items"

    id: Optional[int] = Field(default=None, primary_key=True)
    order_id: int = Field(foreign_key="orders.id", index=True)
    product_id: int = Field(foreign_key="products.id", index=True)
    planned_qty: Decimal = Field(max_digits=10, decimal_places=3)
    actual_qty: Optional[Decimal] = Field(default=None, max_digits=10, decimal_places=3)
    final_price: Optional[Decimal] = Field(default=None, max_digits=14, decimal_places=2)

    order: "Order" = Relationship(back_populates="items")
    product: "Product" = Relationship(back_populates="order_items")
