import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrandColors.yellow, BrandColors.cream],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 128),
                    const SizedBox(height: 16),
                    const Text(
                      'Султан Цех',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: BrandColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Производство и заказы в одном месте',
                      style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 40),
                    _ModeCard(
                      title: 'Цех / рабочий',
                      subtitle: 'Сколько взвесить и собрать сегодня',
                      icon: Icons.scale,
                      color: BrandColors.red,
                      onTap: () => _enter(AppRoutes.workerSummary),
                    ),
                    const SizedBox(height: 16),
                    _ModeCard(
                      title: 'Руководитель',
                      subtitle: 'Продажи, каталог, клиенты, накладные',
                      icon: Icons.dashboard_rounded,
                      color: BrandColors.black,
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
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
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.55))),
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
