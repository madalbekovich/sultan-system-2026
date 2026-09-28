from app.models.order import Order
from app.schemas.order import OrderItemRead, OrderRead

# Order/OrderItem carry only foreign keys; the mobile app also wants the
# client and product names inline so list/detail screens don't need extra
# round trips. Requires order.client and item.product to be eagerly loaded
# (selectinload) before calling this.


def to_order_read(order: Order) -> OrderRead:
    return OrderRead(
        id=order.id,
        client_id=order.client_id,
        client_name=order.client.name,
        created_at=order.created_at,
        delivery_date=order.delivery_date,
        status=order.status,
        total_amount=order.total_amount,
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
