import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
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
