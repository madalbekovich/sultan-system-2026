import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.graphite,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 96),
                    const SizedBox(height: 20),
                    const Text(
                      'Султан Цех',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Производственный учёт',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 40),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BrandColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: BrandColors.redDark, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: Colors.black.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
