import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Diagonal red/yellow stripe bar — the "hazard tape" motif that gives the
/// app its own identity instead of looking like a generic admin template.
/// Used as a thin divider under app bars and section headers.
class HazardStripe extends StatelessWidget {
  const HazardStripe({super.key, this.height = 6});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _HazardPainter()),
    );
  }
}

class _HazardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stripeWidth = 14.0;
    final paintYellow = Paint()..color = BrandColors.yellow;
    final paintBlack = Paint()..color = BrandColors.black;
    canvas.drawRect(Offset.zero & size, paintYellow);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final diagonal = size.width + size.height;
    for (double x = -size.height; x < diagonal; x += stripeWidth * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + stripeWidth, 0)
        ..lineTo(x + stripeWidth, size.height)
        ..close();
      canvas.drawPath(path, paintBlack);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
