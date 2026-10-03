import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Scales its child down slightly on press and back on release — the
/// "this is a physical button" micro-feedback that a flat InkWell alone
/// doesn't give. Wrap any tappable card/row in this instead of InkWell
/// directly when the tap target is a whole card, not just a ripple area.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppDurations.fast,
        curve: AppCurves.press,
        child: widget.child,
      ),
    );
  }
}
