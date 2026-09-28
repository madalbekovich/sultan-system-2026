from app.models.client import Client
from app.models.order import Order

_WAYBILL_TEMPLATE = """
<html>
<head>
<meta charset="utf-8">
<style>
  body {{ font-family: sans-serif; font-size: 12px; }}
  h1 {{ font-size: 18px; }}
  table {{ width: 100%; border-collapse: collapse; margin-top: 12px; }}
  th, td {{ border: 1px solid #333; padding: 6px 8px; text-align: left; }}
  tfoot td {{ font-weight: bold; }}
</style>
</head>
<body>
  <h1>Waybill / Накладная #{order_id}</h1>
  <p>Client: {client_name}<br>Phone: {client_phone}<br>Address: {client_address}</p>
  <p>Delivery date: {delivery_date}</p>
  <table>
    <thead>
      <tr><th>Product</th><th>Planned</th><th>Actual</th><th>Price</th></tr>
    </thead>
    <tbody>
      {rows}
    </tbody>
    <tfoot>
      <tr><td colspan="3">Total</td><td>{total}</td></tr>
    </tfoot>
  </table>
</body>
</html>
"""


def render_waybill_html(order: Order, client: Client) -> str:
    rows = "".join(
        f"<tr><td>{item.product.name}</td><td>{item.planned_qty}</td>"
        f"<td>{item.actual_qty if item.actual_qty is not None else '-'}</td>"
        f"<td>{item.final_price if item.final_price is not None else '-'}</td></tr>"
        for item in order.items
    )
    return _WAYBILL_TEMPLATE.format(
        order_id=order.id,
        client_name=client.name,
        client_phone=client.phone or "-",
        client_address=client.address or "-",
        delivery_date=order.delivery_date.isoformat(),
        rows=rows,
        total=order.total_amount,
    )


def render_waybill_pdf(order: Order, client: Client) -> bytes:
    from weasyprint import HTML

    html = render_waybill_html(order, client)
    return HTML(string=html).write_pdf()
