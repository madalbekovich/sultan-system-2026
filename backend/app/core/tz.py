from datetime import date, datetime
from zoneinfo import ZoneInfo

BISHKEK_TZ = ZoneInfo("Asia/Bishkek")


def now_bishkek() -> datetime:
    return datetime.now(BISHKEK_TZ)


def today_bishkek() -> date:
    return now_bishkek().date()
