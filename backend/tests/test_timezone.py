"""
Regression tests for the Bishkek-timezone fix. The bug this guards against:
the backend host runs in UTC, so a naive `date.today()` call drifts by one
calendar day from Bishkek's actual date during the 00:00-06:00 Bishkek
window (since Bishkek is UTC+6, that window falls on the *previous* UTC
day). We verify the conversion directly against known UTC instants instead
of mocking "now", since the bug is in the conversion, not in the clock.
"""

from datetime import datetime, timezone

from app.core.tz import BISHKEK_TZ


def test_23_30_bishkek_stays_on_the_same_day():
    # 23:30 Bishkek, 11 Oct == 17:30 UTC, 11 Oct — both sides agree on "11".
    utc_dt = datetime(2026, 10, 11, 17, 30, tzinfo=timezone.utc)
    bishkek_dt = utc_dt.astimezone(BISHKEK_TZ)
    assert bishkek_dt.date().isoformat() == "2026-10-11"
    assert (bishkek_dt.hour, bishkek_dt.minute) == (23, 30)


def test_00_30_bishkek_has_already_rolled_to_the_next_day():
    # 00:30 Bishkek, 12 Oct == 18:30 UTC, 11 Oct — naive date.today() on a
    # UTC host would still say "11", one day behind Bishkek's actual "12".
    utc_dt = datetime(2026, 10, 11, 18, 30, tzinfo=timezone.utc)
    bishkek_dt = utc_dt.astimezone(BISHKEK_TZ)
    assert bishkek_dt.date().isoformat() == "2026-10-12"
    assert (bishkek_dt.hour, bishkek_dt.minute) == (0, 30)
