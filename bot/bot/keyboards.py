from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup

from bot.api_client import Category, Product, unit_label


def categories_keyboard(categories: list[Category]) -> InlineKeyboardMarkup:
    rows = [
        [InlineKeyboardButton(text=c.name, callback_data=f"cat:{c.id}")] for c in categories
    ]
    return InlineKeyboardMarkup(inline_keyboard=rows)


def products_keyboard(products: list[Product]) -> InlineKeyboardMarkup:
    rows = [
        [
            InlineKeyboardButton(
                text=f"{p.name} — {p.price_per_unit}/{unit_label(p.unit_type)}",
                callback_data=f"prod:{p.id}",
            )
        ]
        for p in products
    ]
    rows.append([InlineKeyboardButton(text="« Категории", callback_data="back_to_categories")])
    return InlineKeyboardMarkup(inline_keyboard=rows)


def cart_keyboard(has_items: bool) -> InlineKeyboardMarkup:
    rows = [[InlineKeyboardButton(text="+ Добавить ещё", callback_data="back_to_categories")]]
    if has_items:
        rows.append([InlineKeyboardButton(text="✅ Оформить заказ", callback_data="confirm_order")])
        rows.append([InlineKeyboardButton(text="🗑 Очистить корзину", callback_data="clear_cart")])
    return InlineKeyboardMarkup(inline_keyboard=rows)
