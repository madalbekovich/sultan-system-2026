/// The factory operates in Bishkek, so "today"/"tomorrow" must follow
/// Asia/Bishkek (UTC+6, no DST) regardless of the device's own clock or
/// timezone — otherwise a traveling manager or a misconfigured phone would
/// see a different day than the backend/bot.
const _bishkekOffset = Duration(hours: 6);

DateTime nowBishkek() => DateTime.now().toUtc().add(_bishkekOffset);

DateTime todayBishkek() {
  final now = nowBishkek();
  return DateTime(now.year, now.month, now.day);
}
