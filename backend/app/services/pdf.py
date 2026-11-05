from decimal import Decimal

from app.models.client import Client
from app.models.order import Order
from app.models.product import UnitType
from app.services.weight import weight_grams_for

_WAYBILL_TEMPLATE = """
<html>
<head>
<meta charset="utf-8">
<style>
  body {{ font-family: sans-serif; font-size: 12px; }}
  h1 {{ font-size: 18px; }}
  table {{ width: 100%; border-collapse: collapse; margin-top: 12px; }}
  th, td {{ border: 1px solid #333; padding: 6px 8px; text-align: left; }}
  td.num {{ text-align: right; }}
  tfoot td {{ font-weight: bold; }}
  .totals {{ margin-top: 16px; width: 50%; margin-left: auto; }}
  .totals td {{ border: none; padding: 3px 8px; }}
  .totals .label {{ color: #555; }}
  .totals .section {{ font-weight: bold; padding-top: 10px; }}
</style>
</head>
<body>
  <h1>Накладная №{order_id}</h1>
  <p>Клиент: {client_name}<br>Телефон: {client_phone}<br>Адрес: {client_address}</p>
  <p>Дата доставки: {delivery_date}</p>
  <table>
    <thead>
      <tr>
        <th>Товар</th>
        <th>План</th>
        <th>Факт</th>
        <th>Цена до взвешивания</th>
        <th>Цена после взвешивания</th>
      </tr>
    </thead>
    <tbody>
      {rows}
    </tbody>
  </table>
  <table class="totals">
    <tr><td class="section" colspan="2">До взвешивания</td></tr>
    <tr><td class="label">Сумма</td><td class="num">{total_before} сом</td></tr>
    <tr><td class="label">Вес</td><td class="num">{weight_before} кг</td></tr>
    <tr><td class="section" colspan="2">После взвешивания</td></tr>
    <tr><td class="label">Сумма</td><td class="num">{total_after} сом</td></tr>
    <tr><td class="label">Вес</td><td class="num">{weight_after} кг</td></tr>
  </table>
</body>
</html>
"""


def _trim(value: Decimal) -> str:
    """'100.00' -> '100', '12.50' -> '12.5' — trailing zeros read as a
    typo ('100.00 кг' looks like a price, not a round number) on a
    document meant to be read at a glance on the shop floor."""
    text = f"{value:f}"
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return text or "0"


def _unit_label(unit_type) -> str:
    value = unit_type.value if hasattr(unit_type, "value") else unit_type
    return "кг" if value == UnitType.KG.value else "шт"


def render_waybill_html(order: Order, client: Client) -> str:
    total_before = Decimal(0)
    total_after = Decimal(0)
    weight_before_grams = Decimal(0)
    weight_after_grams = Decimal(0)
    rows = []

    for item in order.items:
        product = item.product
        unit = _unit_label(product.unit_type)
        final_price = item.final_price or Decimal(0)
        # The price frozen at order time is for planned_qty — the same
        # per-unit rate applies to whatever the shop actually weighs out,
        # so "after weighing" just re-prices that rate at actual_qty.
        unit_price = (final_price / item.planned_qty) if item.planned_qty else Decimal(0)
        settled_qty = item.actual_qty if item.actual_qty is not None else item.planned_qty
        price_after = unit_price * settled_qty

        total_before += final_price
        total_after += price_after
        weight_before_grams += weight_grams_for(product.unit_type, product.weight_grams, item.planned_qty)
        weight_after_grams += weight_grams_for(product.unit_type, product.weight_grams, settled_qty)

        actual_text = _trim(item.actual_qty) if item.actual_qty is not None else "—"
        rows.append(
            f"<tr><td>{product.name}</td>"
            f"<td class='num'>{_trim(item.planned_qty)} {unit}</td>"
            f"<td class='num'>{actual_text}</td>"
            f"<td class='num'>{_trim(final_price)} сом</td>"
            f"<td class='num'>{_trim(price_after)} сом</td></tr>"
        )

    return _WAYBILL_TEMPLATE.format(
        order_id=order.id,
        client_name=client.name,
        client_phone=client.phone or "—",
        client_address=client.address or "—",
        delivery_date=order.delivery_date.isoformat(),
        rows="".join(rows),
        total_before=_trim(total_before),
        total_after=_trim(total_after),
        weight_before=_trim(weight_before_grams / Decimal(1000)),
        weight_after=_trim(weight_after_grams / Decimal(1000)),
    )


def render_waybill_pdf(order: Order, client: Client) -> bytes:
    from weasyprint import HTML

    html = render_waybill_html(order, client)
    return HTML(string=html).write_pdf()
