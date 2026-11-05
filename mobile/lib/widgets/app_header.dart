import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../core/theme.dart';
import '../core/time.dart';
import '../core/tokens.dart';
import 'brand_logo.dart';

String greetingForNow() {
  final hour = nowBishkek().hour;
  if (hour < 5) return 'Доброй ночи';
  if (hour < 12) return 'Доброе утро';
  if (hour < 18) return 'Добрый день';
  return 'Добрый вечер';
}

/// Dark gradient header with the logo, a time-of-day greeting, and the
/// date — used at the top of both modes' main screen so the app has one
/// consistent "front door" instead of a bare AppBar.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.subtitle, this.action});

  /// Shown under the greeting, e.g. "Цех — сводка по весу".
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.of(context).padding.top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.graphite, AppColors.black],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BrandLogo(size: 46),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingForNow(),
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

String formattedToday() => intl.DateFormat('EEEE, d MMMM', 'ru').format(nowBishkek());
