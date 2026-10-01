import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Large-hit-area button for factory-floor use (tablets, gloves/greasy hands).
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 22) : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color != null ? BrandColors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
