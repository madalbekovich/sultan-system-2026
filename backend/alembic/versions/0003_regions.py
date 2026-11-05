"""add regions, product_region_prices, clients.region_id

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-10

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

BISHKEK_NAME = "Бишкек"
OSH_NAME = "Ош"
BISHKEK_LAT, BISHKEK_LON = 42.8746, 74.5698
OSH_LAT, OSH_LON = 40.5283, 72.7985


def upgrade() -> None:
    op.create_table(
        "regions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("lat", sa.Float(), nullable=False),
        sa.Column("lon", sa.Float(), nullable=False),
    )
    op.create_index("ix_regions_name", "regions", ["name"], unique=True)

    # Seed the two warehouses the UI surfaces today. Explicit column list
    # (not bulk_insert with a model) so this migration keeps working even
    # if the Region model changes shape later.
    regions_table = sa.table(
        "regions",
        sa.column("id", sa.Integer),
        sa.column("name", sa.String),
        sa.column("lat", sa.Float),
        sa.column("lon", sa.Float),
    )
    op.bulk_insert(
        regions_table,
        [
            {"id": 1, "name": BISHKEK_NAME, "lat": BISHKEK_LAT, "lon": BISHKEK_LON},
            {"id": 2, "name": OSH_NAME, "lat": OSH_LAT, "lon": OSH_LON},
        ],
    )
    # Keep the sequence in sync with the explicit ids we just inserted,
    # otherwise the next ORM-side insert would collide with id=1/2.
    op.execute(
        "SELECT setval(pg_get_serial_sequence('regions', 'id'), "
        "(SELECT MAX(id) FROM regions))"
    )

    op.create_table(
        "product_region_prices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("region_id", sa.Integer(), sa.ForeignKey("regions.id"), nullable=False),
        sa.Column("price_per_unit", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.UniqueConstraint("product_id", "region_id", name="uq_product_region"),
    )
    op.create_index(
        "ix_product_region_prices_product_id", "product_region_prices", ["product_id"]
    )
    op.create_index(
        "ix_product_region_prices_region_id", "product_region_prices", ["region_id"]
    )

    # Nullable add, then backfill every existing client to Бишкек — no
    # existing row is left without a region, and nothing else about those
    # rows (or their past orders' frozen prices) changes.
    op.add_column("clients", sa.Column("region_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_clients_region_id", "clients", "regions", ["region_id"], ["id"]
    )
    op.execute(
        f"UPDATE clients SET region_id = "
        f"(SELECT id FROM regions WHERE name = '{BISHKEK_NAME}') "
        f"WHERE region_id IS NULL"
    )


def downgrade() -> None:
    op.drop_constraint("fk_clients_region_id", "clients", type_="foreignkey")
    op.drop_column("clients", "region_id")
    op.drop_index("ix_product_region_prices_region_id", table_name="product_region_prices")
    op.drop_index("ix_product_region_prices_product_id", table_name="product_region_prices")
    op.drop_table("product_region_prices")
    op.drop_index("ix_regions_name", table_name="regions")
    op.drop_table("regions")
