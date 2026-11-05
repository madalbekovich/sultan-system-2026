from aiogram.fsm.state import State, StatesGroup


class CodeEntry(StatesGroup):
    entering_code = State()


class OrderFlow(StatesGroup):
    browsing_category = State()
    browsing_product = State()
    entering_qty = State()
    cart = State()
