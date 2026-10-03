import 'package:flutter/material.dart';

import '../core/tokens.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.elevated,
      ),
      child: ClipOval(
        child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
      ),
    );
  }
}
