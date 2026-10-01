"""Populate realistic-looking demo data on top of the real catalog:
prices (currently all 0), a handful of real-looking clients, and a spread
of orders across this week with varied statuses so the app doesn't look
empty/placeholder during a demo.
"""
import asyncio
import random
import re
from datetime import date, timedelta
from decimal import Decimal

from sqlalchemy import select

from app.db.session import async_session_maker
from app.models.client import Client
from app.models.order import Order, OrderStatus
from app.models.order_item import OrderItem
from app.models.product import Product

random.seed(42)

CLIENTS = [
    ("Народный Маркет", "+996555112233", "Бишкек, мкр. Асанбай 14"),
    ("Фрунзе Продукты", "+996700223344", "Бишкек, ул. Фрунзе 88"),
    ("ЦУМ Ош", "+996770334455", "Ош, ул. Ленина 5"),
    ("Глобус Супермаркет", "+996555445566", "Бишкек, пр. Чуй 123"),
    ("Азат-24", "+996700556677", "Бишкек, ул. Ахунбаева 5"),
    ("Народный Джал", "+996770667788", "Бишкек, мкр. Джал 45"),
    ("Фарух Бишкек", "+996555778899", "Бишкек, ул. Токтогула 12"),
    ("Береке Маркет Карасуу", "+996700889900", "Карасуу, рынок, пав. 7"),
]

WEIGHT_RE = re.compile(r"(\d+),(\d+)\s*гр")
WHOLE_KG_RE = re.compile(r"(\d+)\s*кг")

BASE_RATE_REGULAR = Decimal("480")
BASE_RATE_VACUUM = Decimal("560")
DEFAULT_WEIGHT = Decimal("0.4")


def price_for(product: Product) -> Decimal:
    name = product.name
    weight: Decimal
    m = WEIGHT_RE.search(name)
    if m:
        weight = Decimal(f"{m.group(1)}.{m.group(2)}")
    else:
        m2 = WHOLE_KG_RE.search(name)
        weight = Decimal(m2.group(1)) if m2 else DEFAULT_WEIGHT

    rate = BASE_RATE_VACUUM if "вакуум" in name.lower() else BASE_RATE_REGULAR
    price = (rate * weight).quantize(Decimal("1"))
    # add a bit of per-product variation so prices don't look machine-generated
    jitter = Decimal(random.randint(-15, 15))
    return max(price + jitter, Decimal("50"))


async def main() -> None:
    async with async_session_maker() as session:
        products = (await session.execute(select(Product))).scalars().all()
        for product in products:
            product.price_per_unit = price_for(product)
            session.add(product)
        await session.commit()
        print(f"Проставлены цены для {len(products)} товаров.")

        existing = (await session.execute(select(Client))).scalars().all()
        existing_names = {c.name for c in existing}
        clients = list(existing)
        for name, phone, address in CLIENTS:
            if name in existing_names:
                continue
            client = Client(name=name, phone=phone, address=address)
            session.add(client)
            clients.append(client)
        await session.commit()
        print(f"Клиентов в базе: {len(clients)}")

        products = (await session.execute(select(Product))).scalars().all()
        today = date.today()

        # Day offsets -> (status pool, whether actual_qty gets filled in)
        day_plans = [
            (-1, [OrderStatus.DISPATCHED], True),
            (0, [OrderStatus.IN_ASSEMBLY, OrderStatus.READY, OrderStatus.DISPATCHED], True),
            (1, [OrderStatus.PENDING, OrderStatus.IN_ASSEMBLY], False),
            (2, [OrderStatus.PENDING], False),
            (3, [OrderStatus.PENDING], False),
        ]

        created = 0
        for offset, status_pool, fill_actual in day_plans:
            delivery_date = today + timedelta(days=offset)
            num_orders = random.randint(3, 5)
            for _ in range(num_orders):
                client = random.choice(clients)
                status = random.choice(status_pool)
                order = Order(client_id=client.id, delivery_date=delivery_date, status=status)
                num_items = random.randint(1, 4)
                chosen = random.sample(products, num_items)
                total = Decimal("0")
                for product in chosen:
                    planned_qty = Decimal(random.randint(5, 60))
                    line_total = product.price_per_unit * planned_qty
                    total += line_total
                    actual_qty = None
                    if fill_actual and status != OrderStatus.PENDING:
                        variance = Decimal(random.randint(-2, 2))
                        actual_qty = max(planned_qty + variance, Decimal("1"))
                    order.items.append(
                        OrderItem(
                            product_id=product.id,
                            planned_qty=planned_qty,
                            actual_qty=actual_qty,
                            final_price=line_total,
                        )
                    )
                order.total_amount = total
                session.add(order)
                created += 1

        await session.commit()
        print(f"Создано заказов: {created} (с {today + timedelta(days=-1)} по {today + timedelta(days=3)})")


if __name__ == "__main__":
    asyncio.run(main())
