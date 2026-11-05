from decimal import Decimal

from pydantic import BaseModel

from app.models.product import UnitType


class ProductRead(BaseModel):
    id: int
    category_id: int
    name: str
    unit_type: UnitType
    # Effective price: the base price, unless `client_id` was passed to
    # GET /products/, in which case this is already that client's own
    # price (override if one exists, base otherwise) — callers never need
    # to know which case they're in.
    price_per_unit: Decimal
    is_active: bool
    weight_grams: int | None = None

    model_config = {"from_attributes": True}


class ProductCreate(BaseModel):
    category_id: int
    name: str
    unit_type: UnitType = UnitType.KG
    price_per_unit: Decimal
    is_active: bool = True
    weight_grams: int | None = None


class ProductUpdate(BaseModel):
    category_id: int | None = None
    name: str | None = None
    unit_type: UnitType | None = None
    price_per_unit: Decimal | None = None
    is_active: bool | None = None
    weight_grams: int | None = None


class PriceCoverageRead(BaseModel):
    product_id: int
    product_name: str
    clients_total: int
    clients_with_own_price: int
    clients_missing: int
