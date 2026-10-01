import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/brand_logo.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LoginController>();
  }

  @override
  Widget build(BuildContext context) {
    final targetRoute = (Get.arguments as String?) ?? LoginController.workerHome;

    return Scaffold(
      appBar: AppBar(title: const Text('Вход для сотрудников')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 72),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Логин'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  obscureText: true,
                  onSubmitted: (_) => _submit(targetRoute),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => _controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _submit(targetRoute),
                            child: const Text('Войти', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                ),
                Obx(() {
                  final error = _controller.errorMessage.value;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(error, style: const TextStyle(color: Colors.red)),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(String targetRoute) {
    _controller.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      targetRoute: targetRoute,
    );
  }
}
