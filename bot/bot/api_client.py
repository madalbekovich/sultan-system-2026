from dataclasses import dataclass
from datetime import date
from decimal import Decimal

import httpx

from bot.config import settings


def unit_label(unit_type: str) -> str:
    return "кг" if unit_type == "KG" else "шт"


@dataclass
class Category:
    id: int
    name: str


@dataclass
class Product:
    id: int
    category_id: int
    name: str
    unit_type: str
    price_per_unit: Decimal
    weight_grams: Decimal | None = None


@dataclass
class OrderItemIn:
    product_id: int
    planned_qty: Decimal


@dataclass
class ClientProfile:
    id: int
    client_code: str
    name: str
    phone: str | None
    address: str | None


@dataclass
class OrderSummaryItem:
    id: int
    status: str
    delivery_date: str
    total_amount: Decimal
    item_count: int


class ApiError(RuntimeError):
    def __init__(self, status_code: int, detail: str) -> None:
        super().__init__(f"{status_code}: {detail}")
        self.status_code = status_code
        self.detail = detail


class ApiClient:
    def __init__(self) -> None:
        # X-Bot-Key is what lets the bot call these endpoints at all — the
        # backend rejects every one of them without it (or a manager JWT,
        # which the bot never has). See backend app/api/deps.py.
        self._client = httpx.AsyncClient(
            base_url=settings.API_BASE_URL,
            timeout=10.0,
            headers={"X-Bot-Key": settings.BOT_API_KEY},
        )

    async def close(self) -> None:
        await self._client.aclose()

    async def _get(self, path: str, **kwargs) -> httpx.Response:
        response = await self._client.get(path, **kwargs)
        response.raise_for_status()
        return response

    async def _post(self, path: str, **kwargs) -> httpx.Response:
        response = await self._client.post(path, **kwargs)
        if response.status_code >= 400:
            detail = response.text
            try:
                detail = response.json().get("detail", detail)
            except ValueError:
                pass
            raise ApiError(response.status_code, detail)
        return response

    async def list_categories(self) -> list[Category]:
        response = await self._get("/categories/")
        return [Category(**item) for item in response.json()]

    async def list_products(
        self, category_id: int, client_id: int | None = None
    ) -> list[Product]:
        params = {"category_id": category_id}
        if client_id is not None:
            params["client_id"] = client_id
        response = await self._get("/products/", params=params)
        return [
            Product(
                id=item["id"],
                category_id=item["category_id"],
                name=item["name"],
                unit_type=item["unit_type"],
                price_per_unit=Decimal(str(item["price_per_unit"])),
                weight_grams=Decimal(str(item["weight_grams"]))
                if item.get("weight_grams") is not None
                else None,
            )
            for item in response.json()
        ]

    async def get_client_id_by_tg(self, tg_user_id: int) -> int | None:
        profile = await self.get_client_profile(tg_user_id)
        return profile.id if profile else None

    async def get_client_profile(self, tg_user_id: int) -> ClientProfile | None:
        response = await self._client.get(f"/clients/by-tg/{tg_user_id}")
        if response.status_code == 404:
            return None
        response.raise_for_status()
        data = response.json()
        return ClientProfile(
            id=data["id"],
            client_code=data["client_code"],
            name=data["name"],
            phone=data.get("phone"),
            address=data.get("address"),
        )

    async def bind_client(self, code: str, tg_user_id: int) -> ClientProfile:
        """The one "enter your warehouse code" step that replaces
        self-registration entirely. Raises ApiError(404) for an unknown
        code, ApiError(409) if it's already bound to a different Telegram
        account."""
        response = await self._post("/clients/bind", json={"code": code, "tg_user_id": tg_user_id})
        data = response.json()
        return ClientProfile(
            id=data["id"],
            client_code=data["client_code"],
            name=data["name"],
            phone=data.get("phone"),
            address=data.get("address"),
        )

    async def list_orders_for_client(self, client_id: int) -> list[OrderSummaryItem]:
        response = await self._get("/orders/", params={"client_id": client_id})
        return [
            OrderSummaryItem(
                id=item["id"],
                status=item["status"],
                delivery_date=item["delivery_date"],
                total_amount=Decimal(str(item["total_amount"])),
                item_count=len(item["items"]),
            )
            for item in response.json()
        ]

    async def create_order(
        self, client_id: int, delivery_date: date, items: list[OrderItemIn]
    ) -> dict:
        response = await self._post(
            "/orders/",
            json={
                "client_id": client_id,
                "delivery_date": delivery_date.isoformat(),
                "items": [
                    {"product_id": item.product_id, "planned_qty": str(item.planned_qty)}
                    for item in items
                ],
            },
        )
        return response.json()


api_client = ApiClient()
