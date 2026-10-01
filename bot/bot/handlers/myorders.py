from aiogram import Router
from aiogram.filters import Command
from aiogram.types import Message

from bot.api_client import api_client

router = Router(name="myorders")

_STATUS_LABELS = {
    "PENDING": "⏳ Ожидает",
    "IN_ASSEMBLY": "📦 В сборке",
    "READY": "✅ Готов",
    "DISPATCHED": "🚚 Отправлен",
}


@router.message(Command("myorders"))
async def cmd_myorders(message: Message) -> None:
    client_id = await api_client.get_client_id_by_tg(message.from_user.id)
    if client_id is None:
        await message.answer("У вас пока нет заказов. Отправьте /start, чтобы сделать первый.")
        return

    orders = await api_client.list_orders_for_client(client_id)
    if not orders:
        await message.answer("У вас пока нет заказов. Отправьте /start, чтобы сделать первый.")
        return

    lines = ["📋 Ваши последние заказы:\n"]
    for order in orders[:10]:
        status = _STATUS_LABELS.get(order.status, order.status)
        lines.append(
            f"№{order.id} · {order.delivery_date} · {order.item_count} поз. · "
            f"{order.total_amount} сом · {status}"
        )
    await message.answer("\n".join(lines))
