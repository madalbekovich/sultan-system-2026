from aiogram import Router
from aiogram.filters import CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.types import Message

from bot.api_client import api_client
from bot.handlers.catalog import show_categories
from bot.states import OrderFlow

router = Router(name="start")


@router.message(CommandStart())
async def cmd_start(message: Message, state: FSMContext) -> None:
    await state.clear()
    client_id = await api_client.register_client(
        tg_user_id=message.from_user.id,
        name=message.from_user.full_name,
    )
    await state.update_data(client_id=client_id, cart=[])
    await message.answer(
        f"Добро пожаловать, {message.from_user.full_name}! 👋\nВыберите категорию, чтобы начать заказ:"
    )
    await show_categories(message, state)
