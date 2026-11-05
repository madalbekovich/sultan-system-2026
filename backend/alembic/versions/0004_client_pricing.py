"""retire region-based pricing in favor of per-client (warehouse) prices

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-12

Adds client_product_prices (per-client price overrides, replacing
product_region_prices as the primary pricing mechanism), price_change_log
(audit trail), and clients.client_code/is_archived. Does NOT drop
regions/product_region_prices/clients.region_id — kept read-only for
history so already-placed orders can still show the region they were
priced under; nothing reads them for new pricing decisions any more.

Backfills client_product_prices for any client currently assigned to the
Ош region, copying today's effective Ош override per product — this
preserves exactly today's prices for those clients under the new
mechanism. Clients with no Ош assignment get no new rows (they already
fall back to base price, which stays true under the new mechanism too).
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

OSH_NAME = "Ош"
CODE_PREFIX = "SC-"


def upgrade() -> None:
    op.create_table(
        "client_product_prices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("client_id", sa.Integer(), sa.ForeignKey("clients.id"), nullable=False),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("price_per_unit", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.UniqueConstraint("client_id", "product_id", name="uq_client_product"),
    )
    op.create_index("ix_client_product_prices_client_id", "client_product_prices", ["client_id"])
    op.create_index("ix_client_product_prices_product_id", "client_product_prices", ["product_id"])

    op.create_table(
        "price_change_log",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("client_id", sa.Integer(), sa.ForeignKey("clients.id"), nullable=False),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("old_price", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("new_price", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("changed_by", sa.String(length=100), nullable=False),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_price_change_log_client_id", "price_change_log", ["client_id"])
    op.create_index("ix_price_change_log_product_id", "price_change_log", ["product_id"])

    op.execute("CREATE SEQUENCE IF NOT EXISTS client_code_seq START WITH 1")

    op.add_column("clients", sa.Column("client_code", sa.String(length=20), nullable=True))
    op.add_column(
        "clients",
        sa.Column("is_archived", sa.Boolean(), nullable=False, server_default=sa.false()),
    )

    # Backfill codes for existing clients, in id order, so the format is
    # predictable (SC-0001 = the oldest client row).
    op.execute(
        f"""
        UPDATE clients
        SET client_code = '{CODE_PREFIX}' || lpad(nextval('client_code_seq')::text, 4, '0')
        WHERE client_code IS NULL
        """
    )
    op.alter_column("clients", "client_code", nullable=False)
    op.create_index("ix_clients_client_code", "clients", ["client_code"], unique=True)

    # Preserve today's effective price for clients currently on the Ош
    # region: copy their Ош overrides into the new per-client table.
    op.execute(
        f"""
        INSERT INTO client_product_prices (client_id, product_id, price_per_unit)
        SELECT c.id, prp.product_id, prp.price_per_unit
        FROM clients c
        JOIN regions r ON r.id = c.region_id AND r.name = '{OSH_NAME}'
        JOIN product_region_prices prp ON prp.region_id = r.id
        """
    )


def downgrade() -> None:
    op.drop_index("ix_clients_client_code", table_name="clients")
    op.drop_column("clients", "is_archived")
    op.drop_column("clients", "client_code")
    op.execute("DROP SEQUENCE IF EXISTS client_code_seq")
    op.drop_index("ix_price_change_log_product_id", table_name="price_change_log")
    op.drop_index("ix_price_change_log_client_id", table_name="price_change_log")
    op.drop_table("price_change_log")
    op.drop_index("ix_client_product_prices_product_id", table_name="client_product_prices")
    op.drop_index("ix_client_product_prices_client_id", table_name="client_product_prices")
    op.drop_table("client_product_prices")
