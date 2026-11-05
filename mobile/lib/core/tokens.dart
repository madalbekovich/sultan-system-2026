import 'package:flutter/material.dart';

/// Single source of truth for every color, spacing, radius, shadow and
/// animation constant in the app. Nothing outside this file should
/// hardcode a Color(0x...), a raw EdgeInsets number, a BorderRadius
/// literal or a BoxShadow — reference a token here instead, so a palette
/// or rhythm change is a one-file edit.
abstract class AppColors {
  // Brand — sampled directly from assets/images/logo.jpg (yellow/red/black)
  // and the sausage label in assets/images/hero_meat.jpg (cream/gold), not
  // picked by eye. Every other brand-ish color below is an alias onto
  // these four, so a palette change is a one-line edit here.
  static const brandYellow = Color(0xFFFBDF1B);
  static const brandRed = Color(0xFFD82F21);
  static const brandBlack = Color(0xFF191B1A);
  static const brandCream = Color(0xFFF3DAA3);

  /// Darker red for text/pressed states — brandRed reads weak as body text
  /// or a pressed-state fill at full saturation.
  static const brandRedDark = Color(0xFFA3241A);

  /// Pale washes for badge/pill backgrounds — never fill a large area with
  /// these, they're a tint under an icon or a status pill, not a surface.
  static const brandYellowSoft = Color(0x26FBDF1B); // ~15% alpha
  static const brandRedSoft = Color(0x1AD82F21); // ~10% alpha

  // Existing call sites across the app reference these — kept as aliases
  // onto the brand colors above instead of renaming every usage.
  static const red = brandRed;
  static const redDark = brandRedDark;
  static const yellow = brandYellow;
  static const black = brandBlack;
  static const graphite = Color(0xFF2B2B2E);
  static const cream = Color(0xFFF7F4EE);

  // Neutrals — warm (beige-grey, not blue-grey) so they sit with the cream
  // background and brand black instead of reading as a generic Material grey.
  static const border = Color(0xFFE2DCCB);
  static const textPrimary = black;
  static const textSecondary = Color(0xFF6F6A5E);
  static const textMuted = Color(0xFF9A9486);

  // Order status — derived from the brand palette (muted/ochre/green/blue
  // read as "stage of the day" at a glance) rather than a separate set.
  // "Ожидает" uses the warm neutral grey; "В работе" is the brand yellow
  // (paired with black text/icons wherever it's a fill, never yellow-on-cream).
  static const statusPending = Color(0xFF8F8878);
  static const statusInAssembly = brandYellow;
  static const statusReady = Color(0xFF2E7D32);
  static const statusDispatched = Color(0xFF1565C0);

  static const steelBlue = Color(0xFF3E6E8E);
  static const ochre = Color(0xFF8A6A2E);
  static const moss = Color(0xFF4C7A3D);
  static const plum = Color(0xFF5C5470);
  static const teal = Color(0xFF2B6B6B);

  // Avatar palette — six brand-derived hues so client initials get some
  // variety while still reading as "one system", not confetti. Also the
  // source for every other "pick one of N muted hues" need (product
  // category icons, the manager mode card) so there's one palette, not
  // several independently hand-picked ones.
  static const avatarPalette = [redDark, steelBlue, ochre, moss, plum, teal];

  static const error = Color(0xFFC62828);
  static const success = statusReady;

  // Compact "showing cached data" banner (offline or a slow/erroring
  // backend) — deliberately warm-neutral, not red: this is a transparency
  // note, not an alarm.
  static const staleBanner = Color(0xFFEDE6D3);
  static const staleBannerText = textSecondary;
}

abstract class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract class AppRadius {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 14.0;
}

abstract class AppShadows {
  /// Resting card — the TicketCard look used across list rows.
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Lifted — floating/overlaid elements (logo badge, sheets).
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

abstract class AppDurations {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
  static const staggerStep = Duration(milliseconds: 40);
}

abstract class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const enter = Curves.easeOut;
  static const press = Curves.easeOut;
}
