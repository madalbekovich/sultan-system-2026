from aiogram.fsm.state import State, StatesGroup


class Registration(StatesGroup):
    entering_name = State()
    entering_phone = State()
    entering_address = State()


class OrderFlow(StatesGroup):
    browsing_category = State()
    browsing_product = State()
    entering_qty = State()
    cart = State()
