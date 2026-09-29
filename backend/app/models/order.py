import enum
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime
from sqlmodel import Field, Relationship, SQLModel

if TYPE_CHECKING:
    from app.models.client import Client
    from app.models.order_item import OrderItem


class OrderStatus(str, enum.Enum):
    PENDING = "PENDING"
    IN_ASSEMBLY = "IN_ASSEMBLY"
    READY = "READY"
    DISPATCHED = "DISPATCHED"


class Order(SQLModel, table=True):
    __tablename__ = "orders"

    id: Optional[int] = Field(default=None, primary_key=True)
    client_id: int = Field(foreign_key="clients.id", index=True)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_type=DateTime(timezone=True),
    )
    delivery_date: date = Field(index=True)
    status: OrderStatus = Field(default=OrderStatus.PENDING, index=True)
    total_amount: Decimal = Field(default=Decimal("0"), max_digits=14, decimal_places=2)

    client: "Client" = Relationship(back_populates="orders")
    items: list["OrderItem"] = Relationship(
        back_populates="order", sa_relationship_kwargs={"cascade": "all, delete-orphan"}
    )
