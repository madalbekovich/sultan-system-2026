from pathlib import Path

from aiogram import Router
from aiogram.filters import CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.types import FSInputFile, Message

from bot.api_client import api_client
from bot.handlers.catalog import show_categories
from bot.states import OrderFlow

router = Router(name="start")

_LOGO_PATH = Path(__file__).resolve().parent.parent / "assets" / "logo.jpg"


@router.message(CommandStart())
async def cmd_start(message: Message, state: FSMContext) -> None:
    await state.clear()
    client_id = await api_client.register_client(
        tg_user_id=message.from_user.id,
        name=message.from_user.full_name,
    )
    await state.update_data(client_id=client_id, cart=[])

    caption = (
        f"🐂 Добро пожаловать в Sultan System, {message.from_user.full_name}!\n"
        f"Выберите категорию, чтобы начать заказ:"
    )
    if _LOGO_PATH.exists():
        await message.answer_photo(FSInputFile(_LOGO_PATH), caption=caption)
    else:
        await message.answer(caption)

    await show_categories(message, state)
