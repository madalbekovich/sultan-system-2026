from decimal import Decimal

from app.models.order import Order
from app.schemas.order import OrderItemRead, OrderRead
from app.services.weight import weight_grams_for

# Order/OrderItem carry only foreign keys; the mobile app also wants the
# client and product names inline so list/detail screens don't need extra
# round trips. Requires order.client and item.product to be eagerly loaded
# (selectinload) before calling this.


def _item_weight_grams(item) -> Decimal:
    qty = item.actual_qty if item.actual_qty is not None else item.planned_qty
    return weight_grams_for(item.product.unit_type, item.product.weight_grams, qty)


def to_order_read(order: Order) -> OrderRead:
    return OrderRead(
        id=order.id,
        client_id=order.client_id,
        client_name=order.client.name,
        client_code=order.client.client_code,
        client_region=order.client.region.name if order.client.region else None,
        created_at=order.created_at,
        delivery_date=order.delivery_date,
        status=order.status,
        total_amount=order.total_amount,
        total_weight_grams=sum(
            (_item_weight_grams(item) for item in order.items), Decimal(0)
        ),
        items=[
            OrderItemRead(
                id=item.id,
                product_id=item.product_id,
                product_name=item.product.name,
                unit_type=item.product.unit_type.value,
                planned_qty=item.planned_qty,
                actual_qty=item.actual_qty,
                final_price=item.final_price,
            )
            for item in order.items
        ],
    )
