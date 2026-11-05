import enum
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlmodel import Field, Relationship, SQLModel

if TYPE_CHECKING:
    from app.models.category import Category
    from app.models.order_item import OrderItem


class UnitType(str, enum.Enum):
    KG = "KG"
    PCS = "PCS"


class Product(SQLModel, table=True):
    __tablename__ = "products"

    id: Optional[int] = Field(default=None, primary_key=True)
    category_id: int = Field(foreign_key="categories.id", index=True)
    name: str = Field(index=True, max_length=200)
    unit_type: UnitType = Field(default=UnitType.KG)
    price_per_unit: Decimal = Field(max_digits=12, decimal_places=2)
    is_active: bool = Field(default=True, index=True)
    # Net weight of a single unit, in grams — used to compute order/day
    # total weight. Nullable: older/unfilled products have no weight yet,
    # and such items are simply excluded from weight totals.
    weight_grams: Optional[int] = Field(default=None)

    category: "Category" = Relationship(back_populates="products")
    order_items: list["OrderItem"] = Relationship(back_populates="product")
