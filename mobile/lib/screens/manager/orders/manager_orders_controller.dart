import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/orders_repository.dart';
import '../../../models/order.dart';

class ManagerOrdersController extends GetxController {
  ManagerOrdersController(this._repository);

  final OrdersRepository _repository;

  final selectedDate = DateTime.now().obs;
  final orders = <Order>[].obs;
  final isLoading = true.obs;
  final isOffline = false.obs;
  final updatingOrderIds = <int>{}.obs;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    orders.assignAll(_repository.cachedOrders(_dateKey));
    isLoading.value = orders.isEmpty;
    reload();
  }

  void showDate(DateTime date) {
    selectedDate.value = date;
    orders.assignAll(_repository.cachedOrders(_dateKey));
    reload();
  }

  Future<void> reload() async {
    try {
      final result = await _repository.fetchOrders(deliveryDate: _dateKey);
      orders.assignAll(result);
      isOffline.value = false;
    } catch (_) {
      isOffline.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeStatus(Order order, OrderStatus status) async {
    updatingOrderIds.add(order.id);
    try {
      final updated = await _repository.updateOrderStatus(order.id, status);
      final index = orders.indexWhere((o) => o.id == order.id);
      if (index != -1) orders[index] = updated;
    } catch (_) {
      // Transient — the list keeps the pre-update status, user can retry.
    } finally {
      updatingOrderIds.remove(order.id);
    }
  }
}
