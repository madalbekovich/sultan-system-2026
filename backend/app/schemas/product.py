from decimal import Decimal

from pydantic import BaseModel

from app.models.product import UnitType


class ProductRead(BaseModel):
    id: int
    category_id: int
    name: str
    unit_type: UnitType
    price_per_unit: Decimal
    is_active: bool

    model_config = {"from_attributes": True}


class ProductCreate(BaseModel):
    category_id: int
    name: str
    unit_type: UnitType = UnitType.KG
    price_per_unit: Decimal
    is_active: bool = True


class ProductUpdate(BaseModel):
    category_id: int | None = None
    name: str | None = None
    unit_type: UnitType | None = None
    price_per_unit: Decimal | None = None
    is_active: bool | None = None
