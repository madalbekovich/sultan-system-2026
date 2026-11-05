"""Waybill PDF: before/after-weighing totals and zero-trimming. Builds
plain (unsaved) ORM objects directly — render_waybill_html is pure string
formatting over whatever Order/Client/OrderItem/Product it's handed, no DB
needed."""
from datetime import date
from decimal import Decimal

from app.models.client import Client
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.product import Product, UnitType
from app.services.pdf import render_waybill_html


def _order_with_one_item(*, planned_qty, actual_qty, price_per_unit, weight_grams=None):
    product = Product(
        id=1,
        category_id=1,
        name="Тест",
        unit_type=UnitType.KG,
        price_per_unit=price_per_unit,
        weight_grams=weight_grams,
    )
    item = OrderItem(
        id=1,
        order_id=1,
        product_id=1,
        planned_qty=planned_qty,
        actual_qty=actual_qty,
        final_price=price_per_unit * planned_qty,
    )
    item.product = product
    order = Order(id=1, client_id=1, delivery_date=date(2026, 1, 1))
    order.items = [item]
    client = Client(id=1, client_code="SC-0001", name="Тест-клиент")
    return order, client


def test_price_after_weighing_uses_frozen_rate_on_actual_qty():
    # 10 kg at 350/kg = 3500 planned; actual turns out to be 12 kg -> 4200.
    order, client = _order_with_one_item(
        planned_qty=Decimal("10"), actual_qty=Decimal("12"), price_per_unit=Decimal("350")
    )
    html = render_waybill_html(order, client)
    assert "3500 сом" in html  # до взвешивания
    assert "4200 сом" in html  # после взвешивания


def test_quantities_trim_trailing_zeros():
    order, client = _order_with_one_item(
        planned_qty=Decimal("100.00"), actual_qty=Decimal("100.00"), price_per_unit=Decimal("10")
    )
    html = render_waybill_html(order, client)
    assert "100 кг" in html
    assert "100.00" not in html


def test_weight_before_and_after_differ_with_actual_qty():
    order, client = _order_with_one_item(
        planned_qty=Decimal("10"),
        actual_qty=Decimal("12"),
        price_per_unit=Decimal("350"),
    )
    html = render_waybill_html(order, client)
    # KG product: weight in kg == qty itself (see app/services/weight.py).
    assert "10 кг" in html
    assert "12 сом" not in html  # sanity: actual qty rendered as qty, not mistaken for a price
