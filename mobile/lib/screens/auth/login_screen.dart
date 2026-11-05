import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/tokens.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/version_label.dart';
import 'login_controller.dart';

/// Expects `targetRoute` as the Get argument — where to go after a
/// successful login (worker home or manager home).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginController _controller;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LoginController>();
  }

  @override
  Widget build(BuildContext context) {
    final targetRoute =
        (Get.arguments as String?) ?? LoginController.workerHome;

    return Scaffold(
      appBar: AppBar(title: const Text('Вход для сотрудников')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Expanded(
              // Alignment(0, -0.2) instead of plain Center: with the
              // keyboard closed this sits a little above true geometric
              // center, which reads as "centered" once the logo's visual
              // weight is accounted for — dead center looks low.
              child: Align(
                alignment: const Alignment(0, -0.2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandLogo(size: 72),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            color: AppColors.textMuted,
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _submit(targetRoute),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Obx(
                        () => _controller.isLoading.value
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () => _submit(targetRoute),
                                  child: const Text('Войти',
                                      style: TextStyle(fontSize: 18)),
                                ),
                              ),
                      ),
                      Obx(() {
                        final error = _controller.errorMessage.value;
                        if (error == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const VersionLabel(),
          ],
        ),
      ),
    );
  }

  void _submit(String targetRoute) {
    HapticFeedback.lightImpact();
    _controller.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      targetRoute: targetRoute,
    );
  }
}
