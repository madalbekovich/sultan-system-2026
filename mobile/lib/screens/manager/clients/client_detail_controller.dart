import 'package:get/get.dart';

import '../../../data/orders_repository.dart';
import '../../../models/order.dart';

class ClientDetailController extends GetxController {
  ClientDetailController(this._repository, this.clientId);

  final OrdersRepository _repository;
  final int clientId;

  final orders = <Order>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  double get totalSpent =>
      orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      orders.assignAll(await _repository.fetchOrders(clientId: clientId));
      errorMessage.value = null;
    } catch (_) {
      errorMessage.value = 'Не удалось загрузить заказы клиента.';
    } finally {
      isLoading.value = false;
    }
  }
}
