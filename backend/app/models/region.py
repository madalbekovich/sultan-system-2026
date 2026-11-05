from typing import TYPE_CHECKING, Optional

from sqlmodel import Field, Relationship, SQLModel

if TYPE_CHECKING:
    from app.models.client import Client


class Region(SQLModel, table=True):
    __tablename__ = "regions"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True, max_length=100)
    # Warehouse coordinates — used to find the nearest region for a client's
    # delivery location. Kept extensible (a plain table, not a hardcoded
    # enum) even though the UI only surfaces Бишкек/Ош for now.
    lat: float
    lon: float

    clients: list["Client"] = Relationship(back_populates="region")
