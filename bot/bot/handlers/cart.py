from datetime import date, timedelta
from decimal import Decimal

from aiogram import Router
from aiogram.fsm.context import FSMContext
from aiogram.types import CallbackQuery, Message

from bot.api_client import ApiError, OrderItemIn, api_client, unit_label
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
        lines.append(f"• {entry['name']}: {qty} {unit_label(entry['unit_type'])} = {line_total}")
    lines.append(f"\n*Итого: {total}*")
    return "\n".join(lines)


async def show_cart(message: Message, state: FSMContext) -> None:
    data = await state.get_data()
    cart = data.get("cart", [])
    if not cart:
        text = "🛒 Ваша корзина пуста."
    else:
        text = "🛒 Ваша корзина:\n\n" + _format_cart(cart)
    await message.answer(text, reply_markup=cart_keyboard(bool(cart)), parse_mode="Markdown")


@router.callback_query(lambda c: c.data == "clear_cart")
async def clear_cart(callback: CallbackQuery, state: FSMContext) -> None:
    await state.update_data(cart=[])
    await callback.answer("Корзина очищена.")
    await show_cart(callback.message, state)


@router.callback_query(lambda c: c.data == "confirm_order")
async def confirm_order(callback: CallbackQuery, state: FSMContext) -> None:
    data = await state.get_data()
    cart = data.get("cart", [])
    if not cart:
        await callback.answer("Корзина пуста.", show_alert=True)
        return

    client_id = data.get("client_id")
    if client_id is None:
        await callback.answer()
        await callback.message.answer(
            "⚠️ Сессия сброшена (например, после перезапуска бота). "
            "Отправьте /start и соберите заказ заново."
        )
        return

    items = [
        OrderItemIn(product_id=entry["id"], planned_qty=Decimal(entry["qty"])) for entry in cart
    ]
    delivery_date = date.today() + timedelta(days=1)

    try:
        order = await api_client.create_order(
            client_id=client_id, delivery_date=delivery_date, items=items
        )
    except ApiError:
        await callback.answer()
        await callback.message.answer(
            "⚠️ Что-то пошло не так при оформлении заказа. Попробуйте ещё раз."
        )
        return

    await callback.answer("Заказ оформлен!")
    await state.update_data(cart=[])
    await callback.message.answer(
        f"✅ Заказ №{order['id']} оформлен на {delivery_date.isoformat()}!\n"
        f"Сумма: {order['total_amount']}\n\n"
        f"Мы сообщим, когда он будет готов. Отправьте /start, чтобы сделать новый заказ."
    )
