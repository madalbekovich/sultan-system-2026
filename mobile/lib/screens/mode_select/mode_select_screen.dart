import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/big_button.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sultan System')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.factory, size: 72, color: Colors.deepOrange),
                const SizedBox(height: 24),
                BigButton(
                  label: 'Factory / Worker Mode',
                  icon: Icons.scale,
                  onPressed: () => _enter(AppRoutes.workerSummary),
                ),
                const SizedBox(height: 16),
                BigButton(
                  label: 'Manager / Owner Mode',
                  icon: Icons.dashboard,
                  onPressed: () => _enter(AppRoutes.managerDashboard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _enter(String targetRoute) {
    final auth = Get.find<AuthRepository>();
    if (auth.isLoggedIn) {
      Get.toNamed(targetRoute);
    } else {
      Get.toNamed(AppRoutes.login, arguments: targetRoute);
    }
  }
}
