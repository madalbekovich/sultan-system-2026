import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Small grey app-version mark for the bottom of entry screens (login,
/// mode select). Keep in sync with the `version:` field in pubspec.yaml —
/// this app has no runtime package-info lookup wired up.
class VersionLabel extends StatelessWidget {
  const VersionLabel({super.key});

  static const _version = '0.1.0';

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        'v$_version',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    );
  }
}
