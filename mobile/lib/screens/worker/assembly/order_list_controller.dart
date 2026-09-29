import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/orders_repository.dart';
import '../../../models/order.dart';

class OrderListController extends GetxController {
  OrderListController(this._repository);

  final OrdersRepository _repository;

  final selectedDate = DateTime.now().add(const Duration(days: 1)).obs;
  final orders = <Order>[].obs;
  final isLoading = true.obs;
  final isOffline = false.obs;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    orders.assignAll(_repository.cachedOrders(_dateKey));
    isLoading.value = orders.isEmpty;
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
}
