import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/hazard_stripe.dart';
import '../../widgets/ticket_card.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandLogo(size: 120),
                          const SizedBox(height: 20),
                          const Text(
                            'СУЛТАН ЦЕХ',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'ПРОИЗВОДСТВЕННЫЙ УЧЁТ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: BrandColors.yellow,
                            ),
                          ),
                          const SizedBox(height: 44),
                          _ModeTicket(
                            number: '01',
                            title: 'ЦЕХ',
                            subtitle: 'Взвешивание и сборка заказов',
                            icon: Icons.scale,
                            accentColor: BrandColors.red,
                            onTap: () => _enter(AppRoutes.workerSummary),
                          ),
                          const SizedBox(height: 18),
                          _ModeTicket(
                            number: '02',
                            title: 'РУКОВОДИТЕЛЬ',
                            subtitle: 'Продажи, заказы, каталог, клиенты',
                            icon: Icons.dashboard_rounded,
                            accentColor: BrandColors.yellow,
                            onTap: () => _enter(AppRoutes.managerDashboard),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const HazardStripe(height: 10),
            ],
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

class _ModeTicket extends StatelessWidget {
  const _ModeTicket({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      accentColor: accentColor,
      onTap: onTap,
      child: Row(
        children: [
          Text(
            number,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: accentColor == BrandColors.yellow ? BrandColors.black : accentColor,
              height: 1,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 2, height: 42, color: BrandColors.black),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.black.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Icon(icon, size: 26, color: BrandColors.black),
        ],
      ),
    );
  }
}
