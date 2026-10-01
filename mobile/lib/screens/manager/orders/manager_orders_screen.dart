import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../core/waybill_actions.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/week_day_picker.dart';
import 'manager_orders_controller.dart';

class ManagerOrdersScreen extends StatelessWidget {
  const ManagerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => ManagerOrdersController(Get.find<OrdersRepository>()),
      tag: 'manager_orders',
    )..reload();

    return Scaffold(
      appBar: AppBar(title: const Text('Заказы')),
      body: Column(
        children: [
          Obx(() => controller.isOffline.value ? const OfflineBanner() : const SizedBox.shrink()),
          Obx(() => WeekDayPicker(
                selected: controller.selectedDate.value,
                onSelected: controller.showDate,
              )),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.orders.isEmpty) {
                return const LoadingView();
              }
              if (controller.orders.isEmpty) {
                return ErrorView(
                  message: 'На этот день заказов нет.',
                  onRetry: controller.reload,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return _OrderCard(
                      order: order,
                      isUpdating: controller.updatingOrderIds.contains(order.id),
                      onStatusChange: (status) => controller.changeStatus(order, status),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isUpdating,
    required this.onStatusChange,
  });

  final Order order;
  final bool isUpdating;
  final void Function(OrderStatus status) onStatusChange;

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:
        return Colors.grey;
      case OrderStatus.inAssembly:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.dispatched:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.clientName ?? 'Клиент №${order.clientId}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '№${order.id}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${itemsCountRu(order.items.length)} · ${order.totalAmount.toStringAsFixed(0)} сом',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: isUpdating
                    ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : PopupMenuButton<OrderStatus>(
                        initialValue: order.status,
                        onSelected: onStatusChange,
                        itemBuilder: (context) => OrderStatus.values
                            .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                order.status.label,
                                style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                              ),
                              Icon(Icons.arrow_drop_down, color: _statusColor),
                            ],
                          ),
                        ),
                      ),
              ),
              IconButton(
                tooltip: 'Печать накладной',
                icon: const Icon(Icons.print, color: BrandColors.redDark),
                onPressed: () => WaybillActions.print(order.id),
              ),
              IconButton(
                tooltip: 'Отправить накладную',
                icon: const Icon(Icons.share, color: BrandColors.redDark),
                onPressed: () => WaybillActions.share(order.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
