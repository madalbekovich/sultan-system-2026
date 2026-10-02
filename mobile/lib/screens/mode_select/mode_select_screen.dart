import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';

const _heroImagePath = 'assets/images/hero_meat.jpg';
// The photo's real pixel dimensions — an AspectRatio box this exact shape
// means BoxFit.cover shows the whole image with zero cropping, no overlay
// needed on top of it either.
const _heroAspectRatio = 1251 / 832;

/// Entry screen: the real product photo shown in full (no crop, no scrim
/// over it), with the two modes presented below it as hanging product-tag
/// badges — echoing the oval "Султан" labels tied onto the sausages in the
/// photo — instead of a generic settings-style list of rows.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.graphite,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      BrandLogo(size: 40),
                      SizedBox(width: 10),
                      Text(
                        'Султан Цех',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: _heroAspectRatio,
                  child: Image.asset(
                    _heroImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: BrandColors.black),
                  ),
                ),
                const SizedBox(height: 32),
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
