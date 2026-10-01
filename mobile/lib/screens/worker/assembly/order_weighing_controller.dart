import 'package:get/get.dart';

import '../../../core/error_feedback.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';

class OrderWeighingController extends GetxController {
  OrderWeighingController(this._repository, this.orderId);

  final OrdersRepository _repository;
  final int orderId;

  final order = Rxn<Order>();
  final isLoading = true.obs;
  final savingItemIds = <int>{}.obs;
  final errorMessage = RxnString();

  double get liveTotal {
    final current = order.value;
    if (current == null) return 0;
    return current.items.fold<double>(0, (sum, item) {
      final qty = item.actualQty ?? item.plannedQty;
      final unitPrice =
          item.plannedQty == 0 ? 0.0 : (item.finalPrice ?? 0) / item.plannedQty;
      return sum + qty * unitPrice;
    });
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      order.value = await _repository.fetchOrder(orderId);
    } catch (_) {
      errorMessage.value = 'Не удалось загрузить заказ.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitWeight(int itemId, double actualQty) async {
    savingItemIds.add(itemId);
    try {
      order.value = await _repository.updateItemWeight(itemId, actualQty);
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось сохранить вес.');
    } finally {
      savingItemIds.remove(itemId);
    }
  }

  Future<void> markReady() async {
    try {
      order.value = await _repository.updateOrderStatus(orderId, OrderStatus.ready);
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось обновить статус.');
    }
  }

  Future<void> markDispatched() async {
    try {
      order.value = await _repository.updateOrderStatus(orderId, OrderStatus.dispatched);
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось обновить статус.');
    }
  }
}
