import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A "factory ticket" card: solid black border + a hard offset shadow
/// (no blur) instead of the soft Material drop-shadow every app uses —
/// reads more like a printed tag/receipt than a generic admin card.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.only(right: 4, bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: BrandColors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: accentColor ?? BrandColors.black,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
        color: Colors.white,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: content,
    );
  }
}
