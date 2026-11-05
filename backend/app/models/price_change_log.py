from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional

from sqlalchemy import DateTime
from sqlmodel import Field, SQLModel


class PriceChangeLog(SQLModel, table=True):
    """Audit trail for every client-specific price change (manual edit or
    Excel import) — who changed what, from what, to what, when. Never
    updated or deleted, only appended to."""

    __tablename__ = "price_change_log"

    id: Optional[int] = Field(default=None, primary_key=True)
    client_id: int = Field(foreign_key="clients.id", index=True)
    product_id: int = Field(foreign_key="products.id", index=True)
    old_price: Optional[Decimal] = Field(default=None, max_digits=12, decimal_places=2)
    new_price: Optional[Decimal] = Field(default=None, max_digits=12, decimal_places=2)
    changed_by: str = Field(max_length=100)
    source: str = Field(max_length=20)  # "manual" | "excel_import" | "copy_from_client"
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        sa_type=DateTime(timezone=True),
    )
