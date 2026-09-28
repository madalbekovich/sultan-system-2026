from decimal import Decimal, InvalidOperation

from aiogram import Router
from aiogram.fsm.context import FSMContext
from aiogram.types import CallbackQuery, Message

from bot.api_client import api_client
from bot.keyboards import categories_keyboard, products_keyboard
from bot.states import OrderFlow

router = Router(name="catalog")


async def show_categories(message: Message, state: FSMContext) -> None:
    categories = await api_client.list_categories()
    if not categories:
        await message.answer("No categories available right now — please try later.")
        return
    await state.set_state(OrderFlow.browsing_category)
    await message.answer("📋 Categories:", reply_markup=categories_keyboard(categories))


@router.callback_query(lambda c: c.data == "back_to_categories")
async def back_to_categories(callback: CallbackQuery, state: FSMContext) -> None:
    await callback.answer()
    await show_categories(callback.message, state)


@router.callback_query(lambda c: c.data and c.data.startswith("cat:"))
async def show_products(callback: CallbackQuery, state: FSMContext) -> None:
    category_id = int(callback.data.split(":", 1)[1])
    products = await api_client.list_products(category_id=category_id)
    await callback.answer()
    if not products:
        await callback.message.answer("No products in this category right now.")
        return
    await state.set_state(OrderFlow.browsing_product)
    await state.update_data(category_id=category_id)
    await callback.message.answer("🥩 Products:", reply_markup=products_keyboard(products))


@router.callback_query(lambda c: c.data and c.data.startswith("prod:"))
async def choose_product(callback: CallbackQuery, state: FSMContext) -> None:
    product_id = int(callback.data.split(":", 1)[1])
    data = await state.get_data()
    products = await api_client.list_products(category_id=data["category_id"])
    product = next((p for p in products if p.id == product_id), None)
    if product is None:
        await callback.answer("Product no longer available.", show_alert=True)
        return

    await callback.answer()
    await state.update_data(
        pending_product={
            "id": product.id,
            "name": product.name,
            "unit_type": product.unit_type,
            "price_per_unit": str(product.price_per_unit),
        }
    )
    await state.set_state(OrderFlow.entering_qty)
    await callback.message.answer(
        f"How many {product.unit_type} of *{product.name}* do you need?\n"
        f"Just type a number, e.g. `12.5`.",
        parse_mode="Markdown",
    )


@router.message(OrderFlow.entering_qty)
async def enter_quantity(message: Message, state: FSMContext) -> None:
    try:
        qty = Decimal(message.text.strip().replace(",", "."))
        if qty <= 0:
            raise InvalidOperation
    except InvalidOperation:
        await message.answer("Please send a valid positive number, e.g. `12.5`.")
        return

    data = await state.get_data()
    product = data["pending_product"]
    cart = data.get("cart", [])
    cart.append({**product, "qty": str(qty)})
    await state.update_data(cart=cart, pending_product=None)

    from bot.handlers.cart import show_cart

    await state.set_state(OrderFlow.cart)
    await show_cart(message, state)
