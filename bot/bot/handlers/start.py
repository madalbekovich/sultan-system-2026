from pathlib import Path

from aiogram import Router
from aiogram.filters import CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.types import FSInputFile, Message

from bot.api_client import api_client
from bot.handlers.catalog import show_categories
from bot.handlers.registration import start_registration

router = Router(name="start")

_LOGO_PATH = Path(__file__).resolve().parent.parent / "assets" / "logo.jpg"


@router.message(CommandStart())
async def cmd_start(message: Message, state: FSMContext) -> None:
    await state.clear()
    profile = await api_client.get_client_profile(message.from_user.id)

    caption = f"🐂 Добро пожаловать в Султан Цех, {message.from_user.full_name}!"
    if _LOGO_PATH.exists():
        await message.answer_photo(FSInputFile(_LOGO_PATH), caption=caption)
    else:
        await message.answer(caption)

    if profile is not None and profile.is_complete:
        await state.update_data(client_id=profile.id, cart=[])
        await message.answer(
            "Выберите категорию, чтобы начать заказ.\n\n"
            "💡 /myorders — статус ваших заказов. /profile — изменить контактные данные."
        )
        await show_categories(message, state)
        return

    await message.answer(
        "Это ваш первый заказ — пара вопросов, и дальше оформление будет быстрым."
    )
    await start_registration(message, state, profile)
