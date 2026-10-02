import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api_client.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'data/auth_repository.dart';
import 'data/clients_repository.dart';
import 'data/orders_repository.dart';
import 'data/products_repository.dart';
import 'routes/app_routes.dart';
import 'screens/auth/login_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/manager/manager_shell.dart';
import 'screens/mode_select/mode_select_screen.dart';
import 'screens/worker/worker_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');

  final storage = await LocalStorage.getInstance();
  final apiClient = ApiClient(storage);

  Get.put(storage);
  Get.put(apiClient);
  final authRepository = Get.put(AuthRepository(apiClient, storage));
  Get.put(ProductsRepository(apiClient, storage));
  Get.put(OrdersRepository(apiClient, storage));
  Get.put(ClientsRepository(apiClient));
  Get.put(LoginController(authRepository));

  runApp(const SultanSystemApp());
}

class SultanSystemApp extends StatelessWidget {
  const SultanSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Султан Цех',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.modeSelect,
      getPages: [
        GetPage(name: AppRoutes.modeSelect, page: () => const ModeSelectScreen()),
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(name: AppRoutes.workerSummary, page: () => const WorkerShell()),
        GetPage(name: AppRoutes.managerDashboard, page: () => const ManagerShell()),
      ],
    );
  }
}
