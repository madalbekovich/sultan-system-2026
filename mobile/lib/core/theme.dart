import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';

/// Brand palette lifted from the Sultan logo (red ring, yellow disc, black bull).
abstract class BrandColors {
  static const red = Color(0xFFE2231A);
  static const redDark = Color(0xFFB3160F);
  static const yellow = Color(0xFFFFC72C);
  static const black = Color(0xFF1A1A1A);
  static const cream = Color(0xFFFDF6E8);
  static const paper = Color(0xFFF5EBD3);
}

/// "Scale readout" style for any number the user actually cares about —
/// weights, totals, order counts. Monospace gives it a mechanical,
/// ticket-printer feel instead of looking like regular body text.
TextStyle numberStyle({
  double fontSize = 20,
  FontWeight weight = FontWeight.w800,
  Color color = BrandColors.black,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.5,
  );
}

/// Bold tracked-out uppercase heading — the app's "shouty factory sign"
/// voice, used instead of default Material section titles.
TextStyle headingStyle({double fontSize = 16, Color color = BrandColors.black}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.1,
    color: color,
  );
}

Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const Color(0xFF757575);
    case OrderStatus.inAssembly:
      return const Color(0xFFB3760F);
    case OrderStatus.ready:
      return const Color(0xFF2E7D32);
    case OrderStatus.dispatched:
      return const Color(0xFF1565C0);
  }
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: BrandColors.red,
    primary: BrandColors.red,
    secondary: BrandColors.yellow,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: BrandColors.cream,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      backgroundColor: BrandColors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: BrandColors.black, width: 2),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandColors.black,
        side: const BorderSide(color: BrandColors.black, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.yellow,
      foregroundColor: BrandColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        side: BorderSide(color: BrandColors.black, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: BrandColors.yellow,
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      secondarySelectedColor: BrandColors.yellow,
      side: const BorderSide(color: BrandColors.black, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: BrandColors.black, width: 1.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BrandColors.black, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BrandColors.black, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BrandColors.red, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? BrandColors.red : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? BrandColors.yellow : null,
      ),
    ),
  );
}
