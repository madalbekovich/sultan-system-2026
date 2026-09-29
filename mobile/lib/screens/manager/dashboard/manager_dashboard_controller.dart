import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../models/orders_summary.dart';

class ManagerDashboardController extends GetxController {
  ManagerDashboardController(this._repository);

  final OrdersRepository _repository;

  final summary = Rxn<OrdersSummary>();
  final todaysOrders = <Order>[].obs;
  final isLoading = true.obs;
  final isOffline = false.obs;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  double get totalSalesToday =>
      todaysOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);

  int get dispatchedCount =>
      todaysOrders.where((o) => o.status == OrderStatus.dispatched).length;

  @override
  void onInit() {
    super.onInit();
    summary.value = _repository.cachedSummary(_todayKey);
    todaysOrders.assignAll(_repository.cachedOrders(_todayKey));
    reload();
  }

  Future<void> reload() async {
    isLoading.value = summary.value == null;
    try {
      final results = await Future.wait([
        _repository.fetchSummary(_todayKey),
        _repository.fetchOrders(deliveryDate: _todayKey),
      ]);
      summary.value = results[0] as OrdersSummary;
      todaysOrders.assignAll(results[1] as List<Order>);
      isOffline.value = false;
    } catch (_) {
      isOffline.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
