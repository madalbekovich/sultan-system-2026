"""Replace the placeholder test catalog with the real product list."""
import asyncio
from decimal import Decimal

from sqlalchemy import delete

from app.db.session import async_session_maker
from app.models.category import Category
from app.models.client import Client
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.product import Product, UnitType

SAUSAGES = [
    "Султан чесночный 0,340гр",
    "Султан чесночный 0,320гр",
    "Султан особый 0,340гр",
    "Султан особый 0,320гр",
    "Султан сервелат 0,340гр",
    "Султан сервелат 0,320гр",
    "Султан чесночный дольки",
    "Султан особый дольки",
    "Султан сервелат дольки",
    "Султан халал элитная 0,340гр",
    "Султан халал салями 0,340гр",
    "Султан халал финская 0,340гр",
    "Султан халал мусульманская 0,340гр",
    "Султан ханская 0,480гр",
    "Султан говяжье 0,480гр",
    "Султан конская 0,480гр",
    "Султан сырный 0,340гр",
    "Султан Эстонская 0,480гр",
    "Султан Княжеская 0,610гр",
    "Султан Краковская",
    "Султан Курченка",
    "Султан барашек",
    "Султан говяжье гигант",
    "Султан охотничья палочная 25см",
    "Султан охотничья 12см",
    "Султан докторская",
    "Султан докторская дольки",
    "Султан докторская 0,7",
    "Султан докторская 1 кг",
    "Султан сосиска детская",
    "Султан сосиска говяжья",
    "Султан хот-дог",
    "Султан сосиска береке",
    "Береке салями 0,340гр",
    "Береке салями 0,320гр",
    "Береке чесночная 0,340гр",
    "Береке чесночная 0,320гр",
    "Береке сервелат 0,340гр",
    "Береке сервелат 0,320гр",
    "Береке мусульманская 0,340гр",
    "Береке мусульманская 0,320гр",
]

VACUUM = [
    "Султан чесночный 0,340гр (вакуум)",
    "Султан чесночный 0,320гр (вакуум)",
    "Султан особый 0,340гр (вакуум)",
    "Султан особый 0,320гр (вакуум)",
    "Султан сервелат 0,340гр (вакуум)",
    "Султан сервелат 0,320гр (вакуум)",
    "Султан чесночный дольки (вакуум)",
    "Султан особый дольки (вакуум)",
    "Султан сервелат дольки (вакуум)",
    "Султан халал элитная 0,340гр (вакуум)",
    "Султан халал салями 0,340гр (вакуум)",
    "Султан халал финская 0,340гр (вакуум)",
    "Султан халал мусульманская 0,340гр (вакуум)",
    "Султан ханская 0,480гр (вакуум)",
    "Султан говяжье 0,480гр (вакуум)",
    "Султан конская 0,480гр (вакуум)",
    "Султан сырный 0,340гр (вакуум)",
    "Султан Эстонская 0,480гр (вакуум)",
    "Султан Княжеская 0,610гр (вакуум)",
    "Султан Краковская (вакуум)",
    "Султан Курченка (вакуум)",
    "Султан говяжье гигант (вакуум)",
    "Султан охотничья палочная 25см (вакуум)",
    "Султан охотничья 12см (вакуум)",
    "Султан хот-дог (вакуум)",
    "Береке салями 0,340гр (вакуум)",
    "Береке салями 0,320гр (вакуум)",
    "Береке чесночная 0,340гр (вакуум)",
    "Береке чесночная 0,320гр (вакуум)",
    "Береке сервелат 0,340гр (вакуум)",
    "Береке сервелат 0,320гр (вакуум)",
    "Береке мусульманская 0,340гр (вакуум)",
    "Береке мусульманская 0,320гр (вакуум)",
    "Курдюк (вакуум)",
    "Курдюк (без вакуума)",
    "Крылышки (вакуум)",
    "Крылышки (без вакуума)",
]


async def main() -> None:
    async with async_session_maker() as session:
        # Clear the placeholder test data this session created earlier
        # (orders/items first, they FK into products/clients).
        await session.execute(delete(OrderItem))
        await session.execute(delete(Order))
        await session.execute(delete(Client))
        await session.execute(delete(Product))
        await session.execute(delete(Category))
        await session.commit()

        sausages_cat = Category(name="Колбасы")
        vacuum_cat = Category(name="Вакуум")
        session.add_all([sausages_cat, vacuum_cat])
        await session.flush()

        products = [
            Product(
                category_id=sausages_cat.id,
                name=name,
                unit_type=UnitType.PCS,
                price_per_unit=Decimal("0"),
            )
            for name in SAUSAGES
        ] + [
            Product(
                category_id=vacuum_cat.id,
                name=name,
                unit_type=UnitType.PCS,
                price_per_unit=Decimal("0"),
            )
            for name in VACUUM
        ]
        session.add_all(products)
        await session.commit()

        print(f"Категории: {sausages_cat.name}, {vacuum_cat.name}")
        print(f"Товаров добавлено: {len(products)}")
        print("ВНИМАНИЕ: у всех товаров price_per_unit = 0 — цены нужно проставить вручную.")


if __name__ == "__main__":
    asyncio.run(main())
