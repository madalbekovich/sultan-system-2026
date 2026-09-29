from typing import TYPE_CHECKING, Optional

from sqlalchemy import BigInteger
from sqlmodel import Field, Relationship, SQLModel

if TYPE_CHECKING:
    from app.models.order import Order


class Client(SQLModel, table=True):
    __tablename__ = "clients"

    id: Optional[int] = Field(default=None, primary_key=True)
    tg_user_id: Optional[int] = Field(default=None, index=True, unique=True, sa_type=BigInteger)
    name: str = Field(index=True, max_length=200)
    phone: Optional[str] = Field(default=None, max_length=32)
    address: Optional[str] = Field(default=None, max_length=500)

    orders: list["Order"] = Relationship(back_populates="client")
