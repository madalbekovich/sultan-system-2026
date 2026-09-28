from datetime import date, timedelta
from decimal import Decimal

from aiogram import Router
from aiogram.fsm.context import FSMContext
from aiogram.types import CallbackQuery, Message

from bot.api_client import ApiError, OrderItemIn, api_client
from bot.keyboards import cart_keyboard

router = Router(name="cart")


def _format_cart(cart: list[dict]) -> str:
    lines = []
    total = Decimal("0")
    for entry in cart:
        qty = Decimal(entry["qty"])
        price = Decimal(entry["price_per_unit"])
        line_total = qty * price
        total += line_total
        lines.append(f"• {entry['name']}: {qty} {entry['unit_type']} = {line_total}")
    lines.append(f"\n*Total: {total}*")
    return "\n".join(lines)


async def show_cart(message: Message, state: FSMContext) -> None:
    data = await state.get_data()
    cart = data.get("cart", [])
    if not cart:
        text = "🛒 Your cart is empty."
    else:
        text = "🛒 Your cart:\n\n" + _format_cart(cart)
    await message.answer(text, reply_markup=cart_keyboard(bool(cart)), parse_mode="Markdown")


@router.callback_query(lambda c: c.data == "clear_cart")
async def clear_cart(callback: CallbackQuery, state: FSMContext) -> None:
    await state.update_data(cart=[])
    await callback.answer("Cart cleared.")
    await show_cart(callback.message, state)


@router.callback_query(lambda c: c.data == "confirm_order")
async def confirm_order(callback: CallbackQuery, state: FSMContext) -> None:
    data = await state.get_data()
    cart = data.get("cart", [])
    if not cart:
        await callback.answer("Cart is empty.", show_alert=True)
        return

    items = [
        OrderItemIn(product_id=entry["id"], planned_qty=Decimal(entry["qty"])) for entry in cart
    ]
    delivery_date = date.today() + timedelta(days=1)

    try:
        order = await api_client.create_order(
            client_id=data["client_id"], delivery_date=delivery_date, items=items
        )
    except ApiError:
        await callback.answer()
        await callback.message.answer(
            "⚠️ Something went wrong placing your order. Please try again."
        )
        return

    await callback.answer("Order placed!")
    await state.update_data(cart=[])
    await callback.message.answer(
        f"✅ Order #{order['id']} placed for {delivery_date.isoformat()}!\n"
        f"Total: {order['total_amount']}\n\n"
        f"We'll notify you once it's ready. Send /start to order again."
    )
