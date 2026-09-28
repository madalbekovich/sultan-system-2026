from sqlmodel import SQLModel

from app.models import Category, Client, Order, OrderItem, Product  # noqa: F401

metadata = SQLModel.metadata
