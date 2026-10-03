import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Order status badge: solid-fill pill with a readable label. Kept simple
/// and flat — no rotation or decorative gimmicks, just a clear status
/// indicator that's easy to scan in a list.
class StampBadge extends StatelessWidget {
  const StampBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
