from sqlmodel import SQLModel

from app.models import (  # noqa: F401
    Category,
    Client,
    ClientProductPrice,
    Order,
    OrderItem,
    PriceChangeLog,
    Product,
    ProductRegionPrice,
    Region,
)

metadata = SQLModel.metadata
