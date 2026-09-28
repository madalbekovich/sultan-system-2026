"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-09-29

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

unit_type_enum = sa.Enum("KG", "PCS", name="unittype")
order_status_enum = sa.Enum("PENDING", "IN_ASSEMBLY", "READY", "DISPATCHED", name="orderstatus")


def upgrade() -> None:
    op.create_table(
        "categories",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=120), nullable=False),
    )
    op.create_index("ix_categories_name", "categories", ["name"], unique=True)

    op.create_table(
        "clients",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tg_user_id", sa.BigInteger(), nullable=True),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("phone", sa.String(length=32), nullable=True),
        sa.Column("address", sa.String(length=500), nullable=True),
    )
    op.create_index("ix_clients_tg_user_id", "clients", ["tg_user_id"], unique=True)
    op.create_index("ix_clients_name", "clients", ["name"])

    op.create_table(
        "products",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("category_id", sa.Integer(), sa.ForeignKey("categories.id"), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("unit_type", unit_type_enum, nullable=False, server_default="KG"),
        sa.Column("price_per_unit", sa.Numeric(12, 2), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.create_index("ix_products_category_id", "products", ["category_id"])
    op.create_index("ix_products_name", "products", ["name"])
    op.create_index("ix_products_is_active", "products", ["is_active"])

    op.create_table(
        "orders",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("client_id", sa.Integer(), sa.ForeignKey("clients.id"), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("delivery_date", sa.Date(), nullable=False),
        sa.Column("status", order_status_enum, nullable=False, server_default="PENDING"),
        sa.Column("total_amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
    )
    op.create_index("ix_orders_client_id", "orders", ["client_id"])
    op.create_index("ix_orders_delivery_date", "orders", ["delivery_date"])
    op.create_index("ix_orders_status", "orders", ["status"])

    op.create_table(
        "order_items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("order_id", sa.Integer(), sa.ForeignKey("orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("planned_qty", sa.Numeric(10, 3), nullable=False),
        sa.Column("actual_qty", sa.Numeric(10, 3), nullable=True),
        sa.Column("final_price", sa.Numeric(14, 2), nullable=True),
    )
    op.create_index("ix_order_items_order_id", "order_items", ["order_id"])
    op.create_index("ix_order_items_product_id", "order_items", ["product_id"])


def downgrade() -> None:
    op.drop_table("order_items")
    op.drop_table("orders")
    op.drop_table("products")
    op.drop_table("clients")
    op.drop_table("categories")
    order_status_enum.drop(op.get_bind(), checkfirst=True)
    unit_type_enum.drop(op.get_bind(), checkfirst=True)
