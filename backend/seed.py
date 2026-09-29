import asyncio
from decimal import Decimal

from app.db.session import async_session_maker
from app.models.category import Category
from app.models.client import Client
from app.models.product import Product, UnitType


async def main() -> None:
    async with async_session_maker() as session:
        sausages = Category(name="Sausages")
        vacuum = Category(name="Vacuum packed")
        halal = Category(name="Halal")
        session.add_all([sausages, vacuum, halal])
        await session.flush()

        products = [
            Product(
                category_id=sausages.id,
                name="Sultan Estonian",
                unit_type=UnitType.KG,
                price_per_unit=Decimal("450.00"),
            ),
            Product(
                category_id=sausages.id,
                name="Sultan Doctor's",
                unit_type=UnitType.KG,
                price_per_unit=Decimal("420.00"),
            ),
            Product(
                category_id=vacuum.id,
                name="Vacuum Beef Pack",
                unit_type=UnitType.PCS,
                price_per_unit=Decimal("980.00"),
            ),
            Product(
                category_id=halal.id,
                name="Halal Lamb Sausage",
                unit_type=UnitType.KG,
                price_per_unit=Decimal("610.00"),
            ),
        ]
        session.add_all(products)

        clients = [
            Client(name="Farukh Bishkek", phone="+996700111222", address="Bishkek, Chuy 12"),
            Client(name="Azat-24", phone="+996700333444", address="Bishkek, Ahunbaeva 5"),
        ]
        session.add_all(clients)

        await session.commit()
        print("Seeded:")
        print(f"  categories: {[sausages.name, vacuum.name, halal.name]}")
        print(f"  products: {[p.name for p in products]}")
        print(f"  clients: {[c.name for c in clients]}")


if __name__ == "__main__":
    asyncio.run(main())
