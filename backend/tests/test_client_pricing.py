"""Per-client (warehouse) pricing. Covers: a client with their own price on
a product gets it, a client with no override falls back to base, one
client's price change never touches another client's or an already-placed
order's frozen price, and the Excel-import path is all-or-nothing on a
single bad row. Also a smoke test that the previously wide-open read
endpoints now require credentials.

Each test creates its own category/products/clients and deletes them in a
`finally`-style cleanup, so this is safe to run against the real dev DB.
"""
from decimal import Decimal

from sqlalchemy import delete

from app.models.category import Category
from app.models.client import Client
from app.models.client_product_price import ClientProductPrice
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.price_change_log import PriceChangeLog
from app.models.product import Product, UnitType


async def _make_category(db) -> Category:
    cat = Category(name="__test_client_pricing__")
    db.add(cat)
    await db.commit()
    await db.refresh(cat)
    return cat


async def _make_client(db, code: str) -> Client:
    c = Client(name=f"__test_{code}__", client_code=code)
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


async def _cleanup(db, *, category_id=None, product_ids=(), client_ids=(), order_ids=()):
    for oid in order_ids:
        await db.execute(delete(OrderItem).where(OrderItem.order_id == oid))
        await db.execute(delete(Order).where(Order.id == oid))
    for cid in client_ids:
        await db.execute(delete(PriceChangeLog).where(PriceChangeLog.client_id == cid))
        await db.execute(delete(ClientProductPrice).where(ClientProductPrice.client_id == cid))
    for pid in product_ids:
        await db.execute(delete(ClientProductPrice).where(ClientProductPrice.product_id == pid))
        await db.execute(delete(Product).where(Product.id == pid))
    for cid in client_ids:
        await db.execute(delete(Client).where(Client.id == cid))
    if category_id is not None:
        await db.execute(delete(Category).where(Category.id == category_id))
    await db.commit()


async def test_client_with_own_price_gets_it_others_get_base(client, auth_headers, db):
    category = await _make_category(db)
    with_override = Product(
        category_id=category.id, name="__test_p_with__", unit_type=UnitType.PCS, price_per_unit=Decimal("100.00")
    )
    without_override = Product(
        category_id=category.id, name="__test_p_without__", unit_type=UnitType.PCS, price_per_unit=Decimal("50.00")
    )
    db.add_all([with_override, without_override])
    await db.commit()
    await db.refresh(with_override)
    await db.refresh(without_override)

    client_a = await _make_client(db, "__T0001__")
    client_b = await _make_client(db, "__T0002__")

    resp = await client.post(
        f"/clients/{client_a.id}/price-sheet/import",
        json=[{"row": 1, "product_id": with_override.id, "price": "150.00"}],
        headers=auth_headers,
    )
    assert resp.status_code == 200 and resp.json()["ok"] is True

    order_a = (
        await client.post(
            "/orders/",
            json={
                "client_id": client_a.id,
                "delivery_date": "2026-12-01",
                "items": [
                    {"product_id": with_override.id, "planned_qty": "2"},
                    {"product_id": without_override.id, "planned_qty": "3"},
                ],
            },
            headers=auth_headers,
        )
    ).json()
    by_product = {i["product_id"]: i for i in order_a["items"]}
    assert Decimal(by_product[with_override.id]["final_price"]) == Decimal("300.00")
    assert Decimal(by_product[without_override.id]["final_price"]) == Decimal("150.00")

    # Client B never got an override — must see the base price, not A's.
    order_b = (
        await client.post(
            "/orders/",
            json={
                "client_id": client_b.id,
                "delivery_date": "2026-12-01",
                "items": [{"product_id": with_override.id, "planned_qty": "1"}],
            },
            headers=auth_headers,
        )
    ).json()
    assert Decimal(order_b["items"][0]["final_price"]) == Decimal("100.00")

    await _cleanup(
        db,
        category_id=category.id,
        product_ids=[with_override.id, without_override.id],
        client_ids=[client_a.id, client_b.id],
        order_ids=[order_a["id"], order_b["id"]],
    )


async def test_changing_client_price_does_not_affect_existing_orders(client, auth_headers, db):
    category = await _make_category(db)
    product = Product(
        category_id=category.id, name="__test_frozen__", unit_type=UnitType.PCS, price_per_unit=Decimal("10.00")
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    warehouse = await _make_client(db, "__T0003__")

    await client.post(
        f"/clients/{warehouse.id}/price-sheet/import",
        json=[{"row": 1, "product_id": product.id, "price": "20.00"}],
        headers=auth_headers,
    )
    order = (
        await client.post(
            "/orders/",
            json={
                "client_id": warehouse.id,
                "delivery_date": "2026-12-01",
                "items": [{"product_id": product.id, "planned_qty": "1"}],
            },
            headers=auth_headers,
        )
    ).json()
    assert Decimal(order["items"][0]["final_price"]) == Decimal("20.00")

    # Change the price after the order was placed.
    await client.post(
        f"/clients/{warehouse.id}/price-sheet/import",
        json=[{"row": 1, "product_id": product.id, "price": "35.00"}],
        headers=auth_headers,
    )

    refetched = (await client.get(f"/orders/{order['id']}", headers=auth_headers)).json()
    assert Decimal(refetched["items"][0]["final_price"]) == Decimal("20.00")

    new_order = (
        await client.post(
            "/orders/",
            json={
                "client_id": warehouse.id,
                "delivery_date": "2026-12-02",
                "items": [{"product_id": product.id, "planned_qty": "1"}],
            },
            headers=auth_headers,
        )
    ).json()
    assert Decimal(new_order["items"][0]["final_price"]) == Decimal("35.00")

    await _cleanup(
        db,
        category_id=category.id,
        product_ids=[product.id],
        client_ids=[warehouse.id],
        order_ids=[order["id"], new_order["id"]],
    )


async def test_price_sheet_import_is_all_or_nothing(client, auth_headers, db):
    category = await _make_category(db)
    good_product = Product(
        category_id=category.id, name="__test_good__", unit_type=UnitType.PCS, price_per_unit=Decimal("5.00")
    )
    db.add(good_product)
    await db.commit()
    await db.refresh(good_product)
    warehouse = await _make_client(db, "__T0004__")

    resp = await client.post(
        f"/clients/{warehouse.id}/price-sheet/import",
        json=[
            {"row": 1, "product_id": good_product.id, "price": "15.00"},
            {"row": 2, "product_id": 999999999, "price": "1.00"},  # nonexistent product
        ],
        headers=auth_headers,
    )
    body = resp.json()
    assert body["ok"] is False
    assert any(e["row"] == 2 for e in body["errors"])

    # Row 1 must NOT have been applied even though it was valid on its own.
    sheet = (await client.get(f"/clients/{warehouse.id}/price-sheet", headers=auth_headers)).json()
    row = next(r for r in sheet if r["product_id"] == good_product.id)
    assert row["has_own_price"] is False

    await _cleanup(db, category_id=category.id, product_ids=[good_product.id], client_ids=[warehouse.id])


async def test_orders_endpoint_requires_credentials(client):
    resp = await client.get("/orders/")
    assert resp.status_code == 401


async def test_products_endpoint_requires_credentials(client):
    resp = await client.get("/products/")
    assert resp.status_code == 401


async def test_bot_key_satisfies_product_auth(client, bot_headers):
    resp = await client.get("/products/", headers=bot_headers)
    assert resp.status_code == 200


async def test_rebinding_code_from_different_account_is_rejected(client, bot_headers, db):
    warehouse = await _make_client(db, "__T0005__")

    first = await client.post(
        "/clients/bind", json={"code": warehouse.client_code, "tg_user_id": 910001}, headers=bot_headers
    )
    assert first.status_code == 200
    assert first.json()["is_bound"] is True

    # Same account re-sending /start with the same code: harmless no-op.
    again = await client.post(
        "/clients/bind", json={"code": warehouse.client_code, "tg_user_id": 910001}, headers=bot_headers
    )
    assert again.status_code == 200

    # A different account trying the same code: rejected.
    other = await client.post(
        "/clients/bind", json={"code": warehouse.client_code, "tg_user_id": 910002}, headers=bot_headers
    )
    assert other.status_code == 409

    await _cleanup(db, client_ids=[warehouse.id])


async def test_manager_unbind_allows_rebind_from_new_account(client, auth_headers, bot_headers, db):
    warehouse = await _make_client(db, "__T0006__")
    await client.post(
        "/clients/bind", json={"code": warehouse.client_code, "tg_user_id": 920001}, headers=bot_headers
    )

    unbind_resp = await client.patch(f"/clients/{warehouse.id}/unbind", headers=auth_headers)
    assert unbind_resp.status_code == 200
    assert unbind_resp.json()["is_bound"] is False

    rebind = await client.post(
        "/clients/bind", json={"code": warehouse.client_code, "tg_user_id": 920002}, headers=bot_headers
    )
    assert rebind.status_code == 200
    assert rebind.json()["is_bound"] is True

    await _cleanup(db, client_ids=[warehouse.id])
