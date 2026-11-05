from pathlib import Path

from aiogram import Router
from aiogram.filters import CommandObject, CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.types import FSInputFile, Message

from bot.api_client import ApiError, api_client
from bot.handlers.catalog import show_categories
from bot.handlers.code_entry import ask_for_code, try_bind
from bot.states import CodeEntry

router = Router(name="start")

_LOGO_PATH = Path(__file__).resolve().parent.parent / "assets" / "logo.jpg"


@router.message(CommandStart())
async def cmd_start(message: Message, command: CommandObject, state: FSMContext) -> None:
    await state.clear()

    caption = f"🐂 Добро пожаловать в Султан Цех, {message.from_user.full_name}!"
    if _LOGO_PATH.exists():
        await message.answer_photo(FSInputFile(_LOGO_PATH), caption=caption)
    else:
        await message.answer(caption)

    profile = await api_client.get_client_profile(message.from_user.id)
    if profile is not None:
        await state.update_data(client_id=profile.id, client_code=profile.client_code, cart=[])
        await message.answer(
            "Выберите категорию, чтобы начать заказ.\n\n"
            "💡 /myorders — статус ваших заказов. /profile — ваши данные."
        )
        await show_categories(message, state)
        return

    # Deep-link from a manager: t.me/<bot>?start=SC-0042 — binds instantly
    # without the "введите код" prompt.
    code = (command.args or "").strip()
    if code:
        try:
            bound = await try_bind(message, state, code)
        except ApiError:
            bound = False
        if bound:
            return

    await state.set_state(CodeEntry.entering_code)
    await ask_for_code(message)
