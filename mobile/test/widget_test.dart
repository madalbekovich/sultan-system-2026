import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sultan_system/core/api_client.dart';
import 'package:sultan_system/core/storage.dart';
import 'package:sultan_system/data/auth_repository.dart';
import 'package:sultan_system/data/clients_repository.dart';
import 'package:sultan_system/data/orders_repository.dart';
import 'package:sultan_system/data/products_repository.dart';
import 'package:sultan_system/main.dart';
import 'package:sultan_system/screens/auth/login_controller.dart';

void main() {
  testWidgets('Mode select screen shows both entry points', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.getInstance();
    final apiClient = ApiClient(storage);

    Get.put(storage);
    Get.put(apiClient);
    final authRepository = Get.put(AuthRepository(apiClient, storage));
    Get.put(ProductsRepository(apiClient, storage));
    Get.put(OrdersRepository(apiClient, storage));
    Get.put(ClientsRepository(apiClient));
    Get.put(LoginController(authRepository));

    await tester.pumpWidget(const SultanSystemApp());
    await tester.pumpAndSettle();

    expect(find.text('Цех'), findsOneWidget);
    expect(find.text('Руководитель'), findsOneWidget);
  });
}
