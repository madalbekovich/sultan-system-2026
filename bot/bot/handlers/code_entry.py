from aiogram import Router
from aiogram.filters import Command
from aiogram.fsm.context import FSMContext
from aiogram.types import Message

from bot.api_client import ApiError, api_client
from bot.states import CodeEntry

router = Router(name="code_entry")

_NOT_BOUND_TEXT = (
    "Введите код склада или обратитесь к менеджеру.\n"
    "Код выглядит так: SC-0001."
)


async def ask_for_code(message: Message) -> None:
    await message.answer(_NOT_BOUND_TEXT)


async def try_bind(message: Message, state: FSMContext, code: str) -> bool:
    """Attempts to bind this Telegram account to a warehouse code.
    Returns True on success (and leaves the client in the catalog), False
    if it answered with an error and the caller should keep waiting for a
    better code."""
    from bot.handlers.catalog import show_categories

    try:
        profile = await api_client.bind_client(code, message.from_user.id)
    except ApiError as e:
        if e.status_code == 404:
            await message.answer("Такой код не найден. Проверьте и отправьте снова, или обратитесь к менеджеру.")
        elif e.status_code == 409:
            await message.answer(
                "Этот код уже привязан к другому аккаунту. Обратитесь к руководителю, "
                "чтобы отвязать его перед повторной привязкой."
            )
        else:
            await message.answer("Не удалось проверить код. Попробуйте ещё раз.")
        return False

    await state.update_data(client_id=profile.id, client_code=profile.client_code, cart=[])
    await message.answer(f"Склад {profile.client_code} подключён. Выберите категорию, чтобы сделать заказ:")
    await show_categories(message, state)
    return True


@router.message(CodeEntry.entering_code)
async def on_code(message: Message, state: FSMContext) -> None:
    code = (message.text or "").strip().upper()
    if not code:
        await ask_for_code(message)
        return
    await try_bind(message, state, code)


@router.message(Command("profile"))
async def cmd_profile(message: Message, state: FSMContext) -> None:
    profile = await api_client.get_client_profile(message.from_user.id)
    if profile is None:
        await message.answer("Склад не подключён. Отправьте /start и введите код склада.")
        return
    await message.answer(
        "Данные вашего склада:\n"
        f"Код: {profile.client_code}\n"
        f"Название: {profile.name}\n"
        f"Телефон: {profile.phone or '—'}\n"
        f"Адрес: {profile.address or '—'}\n\n"
        "Изменить данные или цены может только руководитель."
    )
