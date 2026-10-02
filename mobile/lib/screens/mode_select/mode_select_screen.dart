import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';

/// Hero photo behind the mode picker — see assets/images/README.md for the
/// brief. Falls back to a plain gradient until the file is actually added
/// (and declared in pubspec.yaml), so a missing asset never breaks the screen.
const _heroImagePath = 'assets/images/hero_meat.jpg';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.graphite,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background photo (or gradient fallback).
            Image.asset(
              _heroImagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [BrandColors.graphite, BrandColors.black],
                  ),
                ),
              ),
            ),
            // Gradient scrim so the logo and buttons stay legible over any photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [
                    Color(0xCC14100E),
                    Color(0x9914100E),
                    Color(0xF014100E),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const BrandLogo(size: 84),
                  const SizedBox(height: 18),
                  const Text(
                    'Султан Цех',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Производственный учёт',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const Spacer(flex: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      children: [
                        _ModeOption(
                          title: 'Цех',
                          subtitle: 'Взвешивание и сборка заказов',
                          icon: Icons.scale_outlined,
                          onTap: () => _enter(AppRoutes.workerSummary),
                        ),
                        const SizedBox(height: 12),
                        _ModeOption(
                          title: 'Руководитель',
                          subtitle: 'Продажи, заказы, каталог, клиенты',
                          icon: Icons.insights_outlined,
                          onTap: () => _enter(AppRoutes.managerDashboard),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enter(String targetRoute) {
    final auth = Get.find<AuthRepository>();
    if (auth.isLoggedIn) {
      Get.toNamed(targetRoute);
    } else {
      Get.toNamed(AppRoutes.login, arguments: targetRoute);
    }
  }
}

/// Frosted-glass option card sitting on top of the hero photo.
class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: BrandColors.yellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: BrandColors.black, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
