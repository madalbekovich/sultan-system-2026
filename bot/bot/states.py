from aiogram.fsm.state import State, StatesGroup


class OrderFlow(StatesGroup):
    browsing_category = State()
    browsing_product = State()
    entering_qty = State()
    cart = State()
