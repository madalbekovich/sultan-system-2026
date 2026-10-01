import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../core/waybill_actions.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
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
      appBar: AppBar(title: const Text('ЗАКАЗЫ')),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
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

  @override
  Widget build(BuildContext context) {
    final statusColor = orderStatusColor(order.status);
    return TicketCard(
      accentColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.clientName ?? 'Клиент №${order.clientId}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text('№${order.id}', style: numberStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${itemsCountRu(order.items.length)} · ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              Text(
                '${order.totalAmount.toStringAsFixed(0)} сом',
                style: numberStyle(fontSize: 14, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isUpdating)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<OrderStatus>(
                  initialValue: order.status,
                  onSelected: onStatusChange,
                  itemBuilder: (context) => OrderStatus.values
                      .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StampBadge(label: order.status.label, color: statusColor),
                      Icon(Icons.arrow_drop_down, color: statusColor),
                    ],
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Печать накладной',
                icon: const Icon(Icons.print, color: BrandColors.black),
                onPressed: () => WaybillActions.print(order.id),
              ),
              IconButton(
                tooltip: 'Отправить накладную',
                icon: const Icon(Icons.share, color: BrandColors.black),
                onPressed: () => WaybillActions.share(order.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
