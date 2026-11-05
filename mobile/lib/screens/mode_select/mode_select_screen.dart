import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/pressable.dart';
import '../../widgets/version_label.dart';

const _heroImagePath = 'assets/images/hero_meat.jpg';

/// Entry screen: a full-bleed 9:16 photo behind a rounded cream sheet that
/// holds the logo, wordmark and the two mode cards. The sheet sizes itself
/// to its content (lands around the bottom ~40%, not pinned there) so it
/// fits without scrolling from an iPhone SE up to the largest phones.
class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode at the screen's actual pixel width once, not the photo's full
    // resolution — avoids a decode-size jank spike on the entry transition.
    if (_precached) return;
    _precached = true;
    precacheImage(
      ResizeImage(const AssetImage(_heroImagePath), width: _cacheWidth(context)),
      context,
    );
  }

  static int _cacheWidth(BuildContext context) {
    final mq = MediaQuery.of(context);
    return (mq.size.width * mq.devicePixelRatio).round();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _heroImagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: _cacheWidth(context),
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppColors.graphite),
            ),
            // Status bar legibility: white time/icons sit over the photo,
            // so a thin dark fade behind them keeps them readable no
            // matter what's in that part of the shot.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset + 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Eases the photo into the sheet with a seam instead of a hard
            // cut — no Opacity/blur on the photo itself, just a gradient
            // in the sliver the sheet doesn't already cover.
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _ModeSheet(onEnter: _enter),
            ),
          ],
        ),
      ),
    );
  }

  void _enter(String targetRoute) {
    HapticFeedback.selectionClick();
    final auth = Get.find<AuthRepository>();
    if (auth.isLoggedIn) {
      Get.toNamed(targetRoute);
    } else {
      Get.toNamed(AppRoutes.login, arguments: targetRoute);
    }
  }
}

class _ModeSheet extends StatelessWidget {
  const _ModeSheet({required this.onEnter});

  final void Function(String targetRoute) onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 40),
              const SizedBox(height: AppSpacing.xs + 2),
              const Text(
                'Султан Цех',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Выберите режим',
                    style: headingStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _ModeRow(
                title: 'Цех',
                subtitle: 'Взвешивание и сборка заказов',
                icon: Icons.scale_outlined,
                color: AppColors.redDark,
                onTap: () => onEnter(AppRoutes.workerSummary),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ModeRow(
                title: 'Руководитель',
                subtitle: 'Продажи, заказы и клиенты',
                icon: Icons.insights_outlined,
                color: AppColors.steelBlue,
                onTap: () => onEnter(AppRoutes.managerDashboard),
              ),
              const SizedBox(height: AppSpacing.xs),
              const VersionLabel(),
            ],
          ),
        ),
      ),
    );
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
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
