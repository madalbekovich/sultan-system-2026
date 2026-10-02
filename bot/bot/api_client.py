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


@dataclass
class OrderItemIn:
    product_id: int
    planned_qty: Decimal


@dataclass
class ClientProfile:
    id: int
    name: str
    phone: str | None
    address: str | None

    @property
    def is_complete(self) -> bool:
        return bool(self.phone) and bool(self.address)


@dataclass
class OrderSummaryItem:
    id: int
    status: str
    delivery_date: str
    total_amount: Decimal
    item_count: int


class ApiError(RuntimeError):
    pass


class ApiClient:
    def __init__(self) -> None:
        self._client = httpx.AsyncClient(base_url=settings.API_BASE_URL, timeout=10.0)

    async def close(self) -> None:
        await self._client.aclose()

    async def _get(self, path: str, **kwargs) -> httpx.Response:
        response = await self._client.get(path, **kwargs)
        response.raise_for_status()
        return response

    async def _post(self, path: str, **kwargs) -> httpx.Response:
        response = await self._client.post(path, **kwargs)
        if response.status_code >= 400:
            raise ApiError(f"{response.status_code}: {response.text}")
        return response

    async def list_categories(self) -> list[Category]:
        response = await self._get("/categories/")
        return [Category(**item) for item in response.json()]

    async def list_products(self, category_id: int) -> list[Product]:
        response = await self._get("/products/", params={"category_id": category_id})
        return [
            Product(
                id=item["id"],
                category_id=item["category_id"],
                name=item["name"],
                unit_type=item["unit_type"],
                price_per_unit=Decimal(str(item["price_per_unit"])),
            )
            for item in response.json()
        ]

    async def register_client(
        self,
        tg_user_id: int,
        name: str,
        phone: str | None = None,
        address: str | None = None,
    ) -> int:
        payload = {"tg_user_id": tg_user_id, "name": name}
        if phone is not None:
            payload["phone"] = phone
        if address is not None:
            payload["address"] = address
        response = await self._post("/clients/register", json=payload)
        return response.json()["id"]

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
            id=data["id"], name=data["name"], phone=data.get("phone"), address=data.get("address")
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
