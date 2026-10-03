import 'package:flutter/material.dart';

import '../core/tokens.dart';

Color colorForName(String name) {
  if (name.isEmpty) return AppColors.avatarPalette.first;
  return AppColors.avatarPalette[name.hashCode.abs() % AppColors.avatarPalette.length];
}

class ClientAvatar extends StatelessWidget {
  const ClientAvatar({super.key, required this.name, this.size = 42});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = colorForName(name);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: size * 0.42),
      ),
    );
  }
}
