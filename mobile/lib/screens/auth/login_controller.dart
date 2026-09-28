import 'package:get/get.dart';

import '../../core/api_client.dart';
import '../../data/auth_repository.dart';
import '../../routes/app_routes.dart';

class LoginController extends GetxController {
  LoginController(this._authRepository);

  final AuthRepository _authRepository;

  final isLoading = false.obs;
  final errorMessage = RxnString();

  Future<void> login({
    required String username,
    required String password,
    required String targetRoute,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.login(username, password);
      Get.offNamed(targetRoute);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Could not reach the server. Check your connection.';
    } finally {
      isLoading.value = false;
    }
  }

  static const workerHome = AppRoutes.workerSummary;
  static const managerHome = AppRoutes.managerDashboard;
}
