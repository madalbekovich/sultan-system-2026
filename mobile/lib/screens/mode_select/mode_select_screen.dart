import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';

const _heroImagePath = 'assets/images/hero_meat.jpg';

/// Entry screen: a full-bleed product photo with the two modes presented as
/// hanging product-tag badges — echoing the oval "Султан" labels tied onto
/// the sausages in the actual photo — instead of a generic settings-style
/// list of rows.
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
            Image.asset(
              _heroImagePath,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
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
            // Vignette: dark at top (for the wordmark) and bottom (for the
            // tags), clear through the middle so the photo itself still reads.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.22, 0.55, 0.78, 1.0],
                  colors: [
                    Color(0xCC0D0A08),
                    Color(0x330D0A08),
                    Color(0x000D0A08),
                    Color(0xAA0D0A08),
                    Color(0xF20D0A08),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        BrandLogo(size: 40),
                        SizedBox(width: 10),
                        Text(
                          'Султан Цех',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 190,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HangingTag(
                          title: 'Цех',
                          subtitle: 'Взвешивание\nи сборка',
                          icon: Icons.scale_outlined,
                          dropHeight: 18,
                          onTap: () => _enter(AppRoutes.workerSummary),
                        ),
                        _HangingTag(
                          title: 'Руководитель',
                          subtitle: 'Продажи\nи заказы',
                          icon: Icons.insights_outlined,
                          dropHeight: 44,
                          onTap: () => _enter(AppRoutes.managerDashboard),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
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

/// A product-tag badge "hanging" from a short string — [dropHeight] varies
/// per tag so the pair reads as two real tags at slightly different
/// lengths, not a mechanically mirrored pair.
class _HangingTag extends StatelessWidget {
  const _HangingTag({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dropHeight,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double dropHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1.5, height: dropHeight, color: Colors.white.withValues(alpha: 0.55)),
        Material(
          color: BrandColors.cream,
          shape: const StadiumBorder(side: BorderSide(color: BrandColors.red, width: 2)),
          elevation: 6,
          shadowColor: Colors.black54,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              width: 136,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: BrandColors.redDark, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: BrandColors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: Colors.black.withValues(alpha: 0.6), height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
