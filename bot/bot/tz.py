from datetime import date, datetime
from zoneinfo import ZoneInfo

BISHKEK_TZ = ZoneInfo("Asia/Bishkek")


def today_bishkek() -> date:
    return datetime.now(BISHKEK_TZ).date()
