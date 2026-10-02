import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../core/theme.dart';
import 'brand_logo.dart';

const _bannerImagePath = 'assets/images/hero_meat.jpg';

String greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 5) return 'Доброй ночи';
  if (hour < 12) return 'Доброе утро';
  if (hour < 18) return 'Добрый день';
  return 'Добрый вечер';
}

/// Header with the logo, a time-of-day greeting, and the date — used at the
/// top of each mode's main screen. [showProductBanner] swaps the flat dark
/// gradient for the product photo (with a scrim behind the text) — used on
/// the manager dashboard only, so it reads as a deliberate banner there
/// rather than being repeated everywhere.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.subtitle, this.action, this.showProductBanner = false});

  /// Shown under the greeting, e.g. "Цех — сводка по весу".
  final String subtitle;
  final Widget? action;
  final bool showProductBanner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 22),
      decoration: showProductBanner
          ? null
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BrandColors.graphite, BrandColors.black],
              ),
            ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showProductBanner) ...[
            Positioned.fill(
              child: Image.asset(
                _bannerImagePath,
                fit: BoxFit.cover,
                alignment: const Alignment(0.2, 0),
                errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [BrandColors.graphite, BrandColors.black],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.0, 0.62, 1.0],
                    colors: [Color(0xF0100D0B), Color(0x99100D0B), Color(0x4D100D0B)],
                  ),
                ),
              ),
            ),
          ] else
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 24),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const BrandLogo(size: 46),
              const SizedBox(width: 14),
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
        ],
      ),
    );
  }
}

String formattedToday() => intl.DateFormat('EEEE, d MMMM', 'ru').format(DateTime.now());
