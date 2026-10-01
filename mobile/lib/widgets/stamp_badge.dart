import 'package:flutter/material.dart';

/// Order status rendered as an ink-stamp: rotated, dashed-looking double
/// border, outline-only fill — reads like something a QC inspector stamped
/// on a ticket, not a soft Material status chip.
class StampBadge extends StatelessWidget {
  const StampBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
