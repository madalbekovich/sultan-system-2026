from pydantic import BaseModel


class ClientRead(BaseModel):
    id: int
    tg_user_id: int | None
    name: str
    phone: str | None
    address: str | None

    model_config = {"from_attributes": True}


class ClientRegister(BaseModel):
    tg_user_id: int
    name: str
    phone: str | None = None
    address: str | None = None
