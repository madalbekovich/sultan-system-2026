from decimal import Decimal

from pydantic import BaseModel


class ClientRead(BaseModel):
    id: int
    client_code: str
    tg_user_id: int | None
    name: str
    phone: str | None
    address: str | None
    is_archived: bool
    is_bound: bool

    model_config = {"from_attributes": True}


class ClientCreate(BaseModel):
    name: str
    phone: str | None = None
    address: str | None = None
    # If set, copies that client's full price sheet onto the new one as a
    # starting point — the "onboard like this other warehouse" shortcut.
    copy_prices_from_client_id: int | None = None


class ClientUpdate(BaseModel):
    name: str | None = None
    phone: str | None = None
    address: str | None = None
    is_archived: bool | None = None


class ClientBindRequest(BaseModel):
    code: str
    tg_user_id: int


class PriceSheetRowRead(BaseModel):
    product_id: int
    product_name: str
    unit_type: str
    base_price: Decimal
    own_price: Decimal | None
    has_own_price: bool


class PriceSheetImportRow(BaseModel):
    row: int
    product_id: int | None = None
    price: str | None = None


class PriceSheetImportErrorRead(BaseModel):
    row: int
    product_id: int | None
    message: str


class PriceSheetImportResultRead(BaseModel):
    ok: bool
    updated: int = 0
    cleared: int = 0
    errors: list[PriceSheetImportErrorRead] = []


class CopyPricesRequest(BaseModel):
    source_client_id: int
