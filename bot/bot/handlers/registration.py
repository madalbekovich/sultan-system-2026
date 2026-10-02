from aiogram import Router
from aiogram.filters import Command
from aiogram.fsm.context import FSMContext
from aiogram.types import (
    KeyboardButton,
    Message,
    ReplyKeyboardMarkup,
    ReplyKeyboardRemove,
)

from bot.api_client import ClientProfile, api_client
from bot.states import Registration

router = Router(name="registration")


@router.message(Command("profile"))
async def cmd_profile(message: Message, state: FSMContext) -> None:
    profile = await api_client.get_client_profile(message.from_user.id)
    if profile is None:
        await message.answer("Вы ещё не оформляли заказ. Отправьте /start, чтобы начать.")
        return
    await message.answer(
        "Ваши данные:\n"
        f"Имя: {profile.name}\n"
        f"Телефон: {profile.phone or '—'}\n"
        f"Адрес доставки: {profile.address or '—'}\n\n"
        "Чтобы изменить — отправьте /editprofile."
    )


@router.message(Command("editprofile"))
async def cmd_edit_profile(message: Message, state: FSMContext) -> None:
    await state.clear()
    await message.answer("Укажите заново имя, телефон и адрес доставки.")
    await start_registration(message, state, profile=None)

_PHONE_KEYBOARD = ReplyKeyboardMarkup(
    keyboard=[[KeyboardButton(text="📱 Отправить номер телефона", request_contact=True)]],
    resize_keyboard=True,
    one_time_keyboard=True,
)


async def start_registration(message: Message, state: FSMContext, profile: ClientProfile | None) -> None:
    """Ask for whatever's still missing from the client's profile, then
    call `on_done`. Returning clients whose name/phone/address are already
    on file skip straight through — this only interrupts new clients or
    ones who registered before the bot started asking for this.
    """
    await state.update_data(
        reg_name=profile.name if profile else message.from_user.full_name,
        reg_phone=profile.phone if profile else None,
        reg_address=profile.address if profile else None,
    )

    if profile is None or not profile.name:
        await state.set_state(Registration.entering_name)
        await message.answer("Как к вам обращаться? Напишите имя и фамилию:")
        return
    await _ask_phone_or_address(message, state)


async def _ask_phone_or_address(message: Message, state: FSMContext) -> None:
    data = await state.get_data()
    if not data.get("reg_phone"):
        await state.set_state(Registration.entering_phone)
        await message.answer(
            "Укажите номер телефона для связи — нажмите кнопку ниже или введите вручную:",
            reply_markup=_PHONE_KEYBOARD,
        )
        return
    if not data.get("reg_address"):
        await state.set_state(Registration.entering_address)
        await message.answer(
            "Куда доставлять заказ? Укажите адрес (город, улица):",
            reply_markup=ReplyKeyboardRemove(),
        )
        return
    await _finish_registration(message, state)


async def _finish_registration(message: Message, state: FSMContext) -> None:
    from bot.handlers.catalog import show_categories

    data = await state.get_data()
    client_id = await api_client.register_client(
        tg_user_id=message.from_user.id,
        name=data["reg_name"],
        phone=data.get("reg_phone"),
        address=data.get("reg_address"),
    )
    await state.update_data(client_id=client_id, cart=[])
    await message.answer(
        f"Готово, {data['reg_name']}! Теперь выберите категорию, чтобы сделать заказ:",
        reply_markup=ReplyKeyboardRemove(),
    )
    await show_categories(message, state)


@router.message(Registration.entering_name)
async def on_name(message: Message, state: FSMContext) -> None:
    name = (message.text or "").strip()
    if not name:
        await message.answer("Введите, пожалуйста, имя и фамилию текстом.")
        return
    await state.update_data(reg_name=name)
    await _ask_phone_or_address(message, state)


@router.message(Registration.entering_phone)
async def on_phone(message: Message, state: FSMContext) -> None:
    phone = message.contact.phone_number if message.contact else (message.text or "").strip()
    if not phone:
        await message.answer("Отправьте номер телефона — кнопкой или текстом.")
        return
    await state.update_data(reg_phone=phone)
    await _ask_phone_or_address(message, state)


@router.message(Registration.entering_address)
async def on_address(message: Message, state: FSMContext) -> None:
    address = (message.text or "").strip()
    if not address:
        await message.answer("Введите адрес доставки текстом.")
        return
    await state.update_data(reg_address=address)
    await _ask_phone_or_address(message, state)
