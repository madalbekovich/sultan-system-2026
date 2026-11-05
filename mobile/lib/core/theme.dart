import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';
import 'tokens.dart';

export 'tokens.dart';

/// "Scale readout" style for numbers the user actually reads at a glance —
/// weights, totals, order counts. Tabular figures keep digits aligned in a
/// column, like a till receipt, without reaching for a different typeface.
TextStyle numberStyle({
  double fontSize = 18,
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Section heading — bold, slightly tracked, but not full-caps-shouty.
TextStyle headingStyle(
    {double fontSize = 15, Color color = AppColors.textPrimary}) {
  return TextStyle(
    fontFamily: 'Onest',
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
    return (Icons.inventory_2_outlined, AppColors.steelBlue);
  }
  return (Icons.kebab_dining_outlined, AppColors.redDark);
}

Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AppColors.statusPending;
    case OrderStatus.inAssembly:
      return AppColors.statusInAssembly;
    case OrderStatus.ready:
      return AppColors.statusReady;
    case OrderStatus.dispatched:
      return AppColors.statusDispatched;
  }
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    primary: AppColors.red,
    secondary: AppColors.yellow,
    surface: Colors.white,
  );

  const headingFontFamily = 'Onest';
  const bodyFontFamily = 'Manrope';

  const textTheme = TextTheme(
    // Screen-level titles (AppBar, headers).
    titleLarge: TextStyle(
      fontFamily: headingFontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: headingFontFamily,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: headingFontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: AppColors.textPrimary,
    ),
    // Body copy.
    bodyLarge: TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: bodyFontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.cream,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      // Material 3's default toolbar height (64) is taller than this app's
      // compact look calls for — pin it back to the Material 2 height.
      toolbarHeight: 56,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: headingFontFamily,
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.black.withValues(alpha: 0.3),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(
          fontFamily: bodyFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        disabledForegroundColor: AppColors.textMuted,
        side: const BorderSide(color: AppColors.border, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(
          fontFamily: bodyFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.redDark,
        textStyle: const TextStyle(
            fontFamily: bodyFontFamily, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.red,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg))),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
          fontFamily: bodyFontFamily, color: AppColors.textSecondary),
      errorStyle: const TextStyle(
        fontFamily: bodyFontFamily,
        color: AppColors.error,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.red, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.black
            : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.yellow
            : AppColors.textMuted.withValues(alpha: 0.4),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
