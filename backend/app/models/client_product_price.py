from decimal import Decimal
from typing import Optional

from sqlmodel import Field, SQLModel, UniqueConstraint


class ClientProductPrice(SQLModel, table=True):
    """Per-client (warehouse) price override for a product. Absence of a
    row for a given (client_id, product_id) means "use the product's base
    price" — this table only holds overrides, not every client × product
    combo. This replaces the region-based override table as the primary
    pricing mechanism: each client/warehouse now has its own near-complete
    price sheet instead of sharing one of two region prices."""

    __tablename__ = "client_product_prices"
    __table_args__ = (
        UniqueConstraint("client_id", "product_id", name="uq_client_product"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    client_id: int = Field(foreign_key="clients.id", index=True)
    product_id: int = Field(foreign_key="products.id", index=True)
    price_per_unit: Decimal = Field(max_digits=12, decimal_places=2)
