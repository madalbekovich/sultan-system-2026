import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/config.dart';
import '../../../core/refresh_status.dart';
import '../../../core/time.dart';
import '../../../data/orders_repository.dart';
import '../../../models/orders_summary.dart';

class ProductionSummaryController extends GetxController with RefreshStatusMixin {
  ProductionSummaryController(this._repository);

  final OrdersRepository _repository;

  final selectedDate = todayBishkek().obs;
  final summary = Rxn<OrdersSummary>();
  final isLoading = true.obs;

  Timer? _pollTimer;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    reload();
    _pollTimer = Timer.periodic(AppConfig.summaryPollInterval, (_) => reload(silent: true));
    watchConnectivity(reload);
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    disposeRefreshStatus();
    super.onClose();
  }

  void _loadFromCache() {
    final cached = _repository.cachedSummary(_dateKey);
    if (cached != null) summary.value = cached;
  }

  void showDate(DateTime date) {
    selectedDate.value = date;
    _loadFromCache();
    reload();
  }

  Future<void> reload({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    await runGuarded(() async {
      final result = await _repository.fetchSummary(_dateKey);
      summary.value = result;
    });
    isLoading.value = false;
  }
}
