import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// A gently pulsing placeholder block — the loading state for content
/// whose shape we already know (a card, a line of text), so the screen
/// reads as "about to appear" rather than "frozen on a spinner".
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _alpha =
      Tween<double>(begin: 0.06, end: 0.14).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alpha,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: _alpha.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Placeholder shaped like a [TicketCard] row: a leading icon circle, two
/// lines of text, a trailing figure — matches the bordered-card look used
/// everywhere so the loading state doesn't visually clash with the real
/// content that replaces it.
class SkeletonCardRow extends StatelessWidget {
  const SkeletonCardRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 15),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 90, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          SkeletonBox(width: 48, height: 18),
        ],
      ),
    );
  }
}

/// A column of [SkeletonCardRow]s with the list's usual spacing — drop-in
/// replacement for a full-screen spinner on any card-list screen.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.count = 5, this.padding});

  final int count;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const SkeletonCardRow(),
    );
  }
}
