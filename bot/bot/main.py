import asyncio
import logging

from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.fsm.storage.memory import MemoryStorage
from aiogram.types import BotCommand, ErrorEvent

from bot.api_client import api_client
from bot.config import settings
from bot.handlers import cart, catalog, code_entry, myorders, start

logger = logging.getLogger(__name__)


async def main() -> None:
    logging.basicConfig(level=logging.INFO)

    bot = Bot(
        token=settings.TELEGRAM_BOT_TOKEN,
        default=DefaultBotProperties(parse_mode=ParseMode.HTML),
    )
    dp = Dispatcher(storage=MemoryStorage())
    dp.include_router(start.router)
    dp.include_router(code_entry.router)
    dp.include_router(myorders.router)
    dp.include_router(catalog.router)
    dp.include_router(cart.router)

    @dp.errors()
    async def on_error(event: ErrorEvent) -> bool:
        # Without this, any unhandled exception in a handler just gets logged
        # and the user sees nothing happen — looks exactly like "the bot is
        # frozen". Always tell them something went wrong instead.
        logger.exception("Unhandled error", exc_info=event.exception)
        update = event.update
        chat = None
        if update.message:
            chat = update.message.chat
        elif update.callback_query and update.callback_query.message:
            chat = update.callback_query.message.chat
        if chat is not None:
            try:
                await bot.send_message(
                    chat.id,
                    "⚠️ Произошла ошибка. Попробуйте /start, чтобы начать заново.",
                )
            except Exception:
                logger.exception("Could not notify user about the error")
        return True

    try:
        await bot.delete_webhook(drop_pending_updates=True)
        await bot.set_my_commands(
            [
                BotCommand(command="start", description="Новый заказ"),
                BotCommand(command="myorders", description="Мои заказы"),
                BotCommand(command="profile", description="Мои данные"),
            ]
        )
        await dp.start_polling(bot)
    finally:
        await api_client.close()
        await bot.session.close()


if __name__ == "__main__":
    asyncio.run(main())
