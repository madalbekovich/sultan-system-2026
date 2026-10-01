import logging

import httpx

from app.core.config import settings
from app.models.order import Order, OrderStatus

logger = logging.getLogger(__name__)

_STATUS_MESSAGES = {
    OrderStatus.READY: "✅ Ваш заказ №{id} собран и готов к выдаче/доставке!",
    OrderStatus.DISPATCHED: "🚚 Ваш заказ №{id} отправлен.",
}


async def notify_client_order_status(order: Order) -> None:
    """Best-effort push to the client's Telegram chat when an order they
    placed via the bot changes to a status they'd care about. Silently does
    nothing if the bot token isn't configured or the client has no
    tg_user_id (e.g. orders entered by a manager, not via the bot) — this
    must never break the status-update request itself.
    """
    template = _STATUS_MESSAGES.get(order.status)
    if template is None or not settings.TELEGRAM_BOT_TOKEN or order.client.tg_user_id is None:
        return

    text = template.format(id=order.id)
    url = f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/sendMessage"
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.post(
                url, json={"chat_id": order.client.tg_user_id, "text": text}
            )
            response.raise_for_status()
    except httpx.HTTPError:
        logger.warning("Could not notify client %s about order %s", order.client_id, order.id)
