from decimal import Decimal
from typing import Optional

from sqlmodel import Field, SQLModel, UniqueConstraint


class ProductRegionPrice(SQLModel, table=True):
    """Per-region price override for a product. Absence of a row for a
    given (product_id, region_id) means "use the product's base price" —
    this table only holds overrides, not every product × region combo."""

    __tablename__ = "product_region_prices"
    __table_args__ = (
        UniqueConstraint("product_id", "region_id", name="uq_product_region"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    product_id: int = Field(foreign_key="products.id", index=True)
    region_id: int = Field(foreign_key="regions.id", index=True)
    price_per_unit: Decimal = Field(max_digits=12, decimal_places=2)
