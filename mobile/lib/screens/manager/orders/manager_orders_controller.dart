import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/error_feedback.dart';
import '../../../core/refresh_status.dart';
import '../../../core/time.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';

class ManagerOrdersController extends GetxController with RefreshStatusMixin {
  ManagerOrdersController(this._repository);

  final OrdersRepository _repository;

  final selectedDate = todayBishkek().obs;
  final orders = <Order>[].obs;
  final isLoading = true.obs;
  final updatingOrderIds = <int>{}.obs;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    orders.assignAll(_repository.cachedOrders(_dateKey));
    isLoading.value = orders.isEmpty;
    reload();
    watchConnectivity(reload);
  }

  @override
  void onClose() {
    disposeRefreshStatus();
    super.onClose();
  }

  void showDate(DateTime date) {
    selectedDate.value = date;
    orders.assignAll(_repository.cachedOrders(_dateKey));
    reload();
  }

  Future<void> reload() async {
    await runGuarded(() async {
      final result = await _repository.fetchOrders(deliveryDate: _dateKey);
      orders.assignAll(result);
    });
    isLoading.value = false;
  }

  /// Manager-only, permanent. Returns true on success so the caller knows
  /// whether to show an error.
  Future<bool> deleteOrder(Order order) async {
    try {
      await _repository.deleteOrder(order.id);
      orders.removeWhere((o) => o.id == order.id);
      return true;
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось удалить заказ.');
      return false;
    }
  }

  Future<void> changeStatus(Order order, OrderStatus status) async {
    updatingOrderIds.add(order.id);
    try {
      final updated = await _repository.updateOrderStatus(order.id, status);
      final index = orders.indexWhere((o) => o.id == order.id);
      if (index != -1) orders[index] = updated;
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось изменить статус заказа.');
    } finally {
      updatingOrderIds.remove(order.id);
    }
  }
}
