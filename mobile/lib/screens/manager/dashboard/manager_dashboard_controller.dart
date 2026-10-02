import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/orders_repository.dart';
import '../../../models/dashboard_analytics.dart';
import '../../../models/order.dart';

class ManagerDashboardController extends GetxController {
  ManagerDashboardController(this._repository);

  final OrdersRepository _repository;

  final analytics = Rxn<DashboardAnalytics>();
  final todaysOrders = <Order>[].obs;
  final isLoading = true.obs;
  final isOffline = false.obs;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  double get totalSalesToday =>
      todaysOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);

  double get averageOrderValue =>
      todaysOrders.isEmpty ? 0 : totalSalesToday / todaysOrders.length;

  int get dispatchedCount =>
      todaysOrders.where((o) => o.status == OrderStatus.dispatched).length;

  double get weekTotal =>
      analytics.value?.dailySales.fold<double>(0, (sum, d) => sum + d.totalAmount) ?? 0;

  @override
  void onInit() {
    super.onInit();
    todaysOrders.assignAll(_repository.cachedOrders(_todayKey));
    reload();
  }

  Future<void> reload() async {
    isLoading.value = analytics.value == null;
    try {
      final results = await Future.wait([
        _repository.fetchOrders(deliveryDate: _todayKey),
        _repository.fetchDashboardAnalytics(),
      ]);
      todaysOrders.assignAll(results[0] as List<Order>);
      analytics.value = results[1] as DashboardAnalytics;
      isOffline.value = false;
    } catch (_) {
      isOffline.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
