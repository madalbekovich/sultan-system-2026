import '../models/product.dart';

const _nbsp = ' ';

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_nbsp);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// "162 019" — grouped digits, no currency label. For spots that show the
/// number and "сом" in two different text styles side by side.
String formatMoneyNumber(num amount) {
  final rounded = amount.round();
  final grouped = _groupThousands(rounded.abs().toString());
  return '${rounded < 0 ? '-' : ''}$grouped';
}

/// "162 019 сом" — rounded to whole currency units, grouped with a
/// non-breaking space so the number never wraps mid-figure.
String formatMoney(num amount) => '${formatMoneyNumber(amount)}$_nbsp сом';

/// "162к" — compact form for tight spaces like chart bars.
String formatMoneyCompact(num amount) {
  if (amount >= 1000 || amount <= -1000) {
    return '${(amount / 1000).toStringAsFixed(0)}к';
  }
  return amount.toStringAsFixed(0);
}

String _trimQty(double qty) {
  if (qty == qty.roundToDouble()) return qty.round().toString();
  var s = qty.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s.replaceFirst('.', ',');
}

/// "500 шт" / "2,5 кг" — whole counts drop the decimal, real fractions
/// keep up to 2 digits with a comma (Russian decimal convention).
String formatQty(double qty, UnitType unit) => '${_trimQty(qty)} ${unit.label}';

/// Same trimming rule, for when the caller already has a Russian-style
/// unit string ('кг'/'шт') instead of a [UnitType] — the worker summary
/// API returns qty + a unit label separately.
String formatQtyLabel(double qty, String unitLabel) => '${_trimQty(qty)} $unitLabel';

/// "168 сом/шт"
String formatPricePerUnit(double price, UnitType unit) =>
    '${_trimQty(price)} сом/${unit.label}';

/// "+996 700 556 677" — accepts "996700556677", "+996700556677" or a bare
/// 9-digit local number; falls back to the raw input if it doesn't look
/// like a Kyrgyz mobile number so we never hide real (if oddly-formatted)
/// data from the user.
String formatPhone(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  String national;
  if (digits.length == 12 && digits.startsWith('996')) {
    national = digits.substring(3);
  } else if (digits.length == 9) {
    national = digits;
  } else {
    return raw;
  }
  return '+996 ${national.substring(0, 3)} ${national.substring(3, 6)} ${national.substring(6, 9)}';
}
