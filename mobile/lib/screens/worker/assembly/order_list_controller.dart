import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/refresh_status.dart';
import '../../../core/time.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';

class OrderListController extends GetxController with RefreshStatusMixin {
  OrderListController(this._repository);

  final OrdersRepository _repository;

  final selectedDate = todayBishkek().obs;
  final orders = <Order>[].obs;
  final isLoading = true.obs;

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
}
