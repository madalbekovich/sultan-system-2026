import 'package:flutter/material.dart';

/// A muted, professional palette (not rainbow-random) so client avatars
/// get some visual variety instead of every row looking identical, while
/// still reading as "one system" rather than a confetti of colors.
const _palette = [
  Color(0xFFA81D14), // brand red-dark
  Color(0xFF3E6E8E), // steel blue
  Color(0xFF8A6A2E), // ochre
  Color(0xFF4C7A3D), // moss
  Color(0xFF5C5470), // muted plum
  Color(0xFF2B6B6B), // teal
];

Color colorForName(String name) {
  if (name.isEmpty) return _palette.first;
  return _palette[name.hashCode.abs() % _palette.length];
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
