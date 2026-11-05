from typing import TYPE_CHECKING, Optional

from sqlalchemy import BigInteger
from sqlmodel import Field, Relationship, SQLModel

if TYPE_CHECKING:
    from app.models.order import Order
    from app.models.region import Region


class Client(SQLModel, table=True):
    __tablename__ = "clients"

    id: Optional[int] = Field(default=None, primary_key=True)
    tg_user_id: Optional[int] = Field(default=None, index=True, unique=True, sa_type=BigInteger)
    name: str = Field(index=True, max_length=200)
    phone: Optional[str] = Field(default=None, max_length=32)
    address: Optional[str] = Field(default=None, max_length=500)
    # Short, human-readable, immutable warehouse code (e.g. "SC-0007") — the
    # manager-facing identity used for search, bot code entry, and Excel.
    # Separate from the internal id so it never changes even if rows are
    # reordered/archived.
    client_code: str = Field(index=True, unique=True, max_length=20)
    # Hidden from catalogs/search but never deleted — history (orders) is
    # preserved either way. Set by a manager, never automatic.
    is_archived: bool = Field(default=False, index=True)
    # Historical only — region-based pricing is retired in favor of
    # per-client (client_product_prices) pricing. Kept so already-placed
    # orders can still display the region they were priced under; no
    # longer read when creating new orders.
    region_id: Optional[int] = Field(default=None, foreign_key="regions.id")

    orders: list["Order"] = Relationship(back_populates="client")
    region: Optional["Region"] = Relationship(back_populates="clients")
