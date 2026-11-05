from decimal import Decimal

from aiogram import Router
from aiogram.fsm.context import FSMContext
from aiogram.types import CallbackQuery, Message

from bot.api_client import ApiError, OrderItemIn, api_client, unit_label
from bot.keyboards import cart_keyboard
from bot.tz import today_bishkek

router = Router(name="cart")


def _trim(value: Decimal) -> str:
    text = f"{value:f}"
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return text or "0"


def _item_weight_grams(entry: dict) -> Decimal:
    """Weight for one cart line, in grams. For a KG product the entered
    quantity already *is* the weight (qty 12 means 12 kg) — weight_grams
    is irrelevant there. For a PCS product, weight_grams is the weight of
    one piece; with none set, the line simply doesn't contribute yet."""
    qty = Decimal(entry["qty"])
    if entry["unit_type"] == "KG":
        return qty * Decimal(1000)
    weight_grams = entry.get("weight_grams")
    if weight_grams is None:
        return Decimal(0)
    return qty * Decimal(weight_grams)


def _format_cart(cart: list[dict]) -> str:
    lines = []
    total = Decimal("0")
    total_weight_grams = Decimal("0")
    for entry in cart:
        qty = Decimal(entry["qty"])
        price = Decimal(entry["price_per_unit"])
        line_total = qty * price
        total += line_total
        total_weight_grams += _item_weight_grams(entry)
        lines.append(
            f"• {entry['name']}: {_trim(qty)} {unit_label(entry['unit_type'])} = {_trim(line_total)} с"
        )

    lines.append(f"\n*Сумма: {_trim(total)} с*")
    lines.append(f"*Общий вес: {_trim(total_weight_grams / Decimal(1000))} кг*")
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
    delivery_date = today_bishkek()

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
    weight_grams = Decimal(str(order.get("total_weight_grams") or 0))
    weight_line = f"Общий вес: {_trim(weight_grams / Decimal(1000))} кг\n" if weight_grams else ""
    await callback.message.answer(
        f"✅ Заказ №{order['id']} оформлен!\n"
        f"Доставка: сегодня, {delivery_date.strftime('%d.%m.%Y')}\n"
        f"{weight_line}"
        f"Сумма: {_trim(Decimal(str(order['total_amount'])))} с\n\n"
        f"Мы сообщим, когда он будет готов. Отправьте /start, чтобы сделать новый заказ."
    )
