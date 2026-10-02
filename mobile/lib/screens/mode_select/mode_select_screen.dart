import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';

const _heroImagePath = 'assets/images/hero_meat.jpg';
// The photo's real pixel dimensions — an AspectRatio box this exact shape
// means BoxFit.cover shows the whole image with zero cropping.
const _heroAspectRatio = 1251 / 832;

/// Entry screen: same light, calm look as the rest of the app (cream
/// background, bordered cards) instead of a one-off dark showpiece — the
/// product photo sits as a banner up top and fades into the page, and the
/// two modes are plain, legible rows, not decorative badges.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: BrandColors.cream,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: _heroAspectRatio,
                  child: Image.asset(
                    _heroImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: BrandColors.graphite),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BrandLogo(size: 48),
                            SizedBox(height: 10),
                            Text(
                              'Султан Цех',
                              style: TextStyle(
                                color: BrandColors.black,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Выберите режим', style: headingStyle(fontSize: 13, color: Colors.black54)),
                      const SizedBox(height: 12),
                      _ModeRow(
                        title: 'Цех',
                        subtitle: 'Взвешивание и сборка заказов',
                        icon: Icons.scale_outlined,
                        color: BrandColors.redDark,
                        onTap: () => _enter(AppRoutes.workerSummary),
                      ),
                      const SizedBox(height: 10),
                      _ModeRow(
                        title: 'Руководитель',
                        subtitle: 'Продажи, заказы и клиенты',
                        icon: Icons.insights_outlined,
                        color: const Color(0xFF3E6E8E),
                        onTap: () => _enter(AppRoutes.managerDashboard),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BrandColors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.black.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
