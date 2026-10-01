import 'package:flutter/material.dart';

/// Brand palette lifted from the Sultan logo (red ring, yellow disc, black bull).
abstract class BrandColors {
  static const red = Color(0xFFE2231A);
  static const redDark = Color(0xFFB3160F);
  static const yellow = Color(0xFFFFC72C);
  static const black = Color(0xFF1A1A1A);
  static const cream = Color(0xFFFFF8E7);
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
      backgroundColor: BrandColors.red,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandColors.redDark,
        side: const BorderSide(color: BrandColors.red, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.yellow,
      foregroundColor: BrandColors.black,
    ),
    chipTheme: ChipThemeData(
      selectedColor: BrandColors.yellow,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      secondarySelectedColor: BrandColors.yellow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
