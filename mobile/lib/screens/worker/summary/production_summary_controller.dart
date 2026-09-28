import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/config.dart';
import '../../../data/orders_repository.dart';
import '../../../models/orders_summary.dart';

class ProductionSummaryController extends GetxController {
  ProductionSummaryController(this._repository);

  final OrdersRepository _repository;

  final selectedDate = DateTime.now().obs;
  final summary = Rxn<OrdersSummary>();
  final isLoading = true.obs;
  final isOffline = false.obs;

  Timer? _pollTimer;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    refresh();
    _pollTimer = Timer.periodic(AppConfig.summaryPollInterval, (_) => refresh(silent: true));
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  void _loadFromCache() {
    final cached = _repository.cachedSummary(_dateKey);
    if (cached != null) summary.value = cached;
  }

  void showToday() {
    selectedDate.value = DateTime.now();
    _loadFromCache();
    refresh();
  }

  void showTomorrow() {
    selectedDate.value = DateTime.now().add(const Duration(days: 1));
    _loadFromCache();
    refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final result = await _repository.fetchSummary(_dateKey);
      summary.value = result;
      isOffline.value = false;
    } catch (_) {
      isOffline.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
