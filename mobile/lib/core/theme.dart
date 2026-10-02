import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';

/// Brand palette lifted from the Sultan logo (red ring, yellow disc, black bull).
/// Used as functional accent color (primary actions, status), not decoration.
abstract class BrandColors {
  static const red = Color(0xFFD42A1F);
  static const redDark = Color(0xFFA81D14);
  static const yellow = Color(0xFFE8A935);
  static const black = Color(0xFF1C1C1E);
  static const graphite = Color(0xFF2B2B2E);
  static const cream = Color(0xFFF7F4EE);
  static const border = Color(0xFFE2DCCB);
}

/// "Scale readout" style for numbers the user actually reads at a glance —
/// weights, totals, order counts. Monospace keeps them aligned and easy to
/// scan, like a till receipt, without shouting.
TextStyle numberStyle({
  double fontSize = 18,
  FontWeight weight = FontWeight.w700,
  Color color = BrandColors.black,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
  );
}

/// Section heading — bold, slightly tracked, but not full-caps-shouty.
TextStyle headingStyle({double fontSize = 15, Color color = BrandColors.black}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: color,
  );
}

/// Product icon/color by name, since not every list that shows a product
/// (e.g. the worker's weight summary) also carries its category — vacuum
/// items are reliably named "...(вакуум)" in this catalog.
(IconData, Color) productVisual(String productName) {
  final name = productName.toLowerCase();
  if (name.contains('вакуум')) {
    return (Icons.inventory_2_outlined, const Color(0xFF3E6E8E));
  }
  return (Icons.kebab_dining_outlined, BrandColors.redDark);
}

Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const Color(0xFF6B6B6B);
    case OrderStatus.inAssembly:
      return const Color(0xFFA06A17);
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
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandColors.black,
        side: const BorderSide(color: Color(0xFFBFBFBF), width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.black,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    chipTheme: ChipThemeData(
      selectedColor: BrandColors.black,
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      secondarySelectedColor: BrandColors.black,
      side: const BorderSide(color: Color(0xFFD8D2C0), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: BrandColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCFC9B8), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCFC9B8), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: BrandColors.red, width: 1.6),
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
