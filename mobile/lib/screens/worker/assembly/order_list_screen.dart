import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/status_views.dart';
import 'order_list_controller.dart';
import 'order_weighing_screen.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => OrderListController(Get.find<OrdersRepository>()),
      tag: 'order_list',
    )..reload();

    return Scaffold(
      appBar: AppBar(title: const Text('Сборка заказов')),
      body: Column(
        children: [
          Obx(() => controller.isOffline.value ? const OfflineBanner() : const SizedBox.shrink()),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.orders.isEmpty) {
                return const LoadingView();
              }
              if (controller.orders.isEmpty) {
                return ErrorView(
                  message: 'На этот день заказов не запланировано.',
                  onRetry: controller.reload,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.separated(
                  itemCount: controller.orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      title: Text(order.clientName ?? 'Клиент №${order.clientId}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      subtitle: Text('${itemsCountRu(order.items.length)} · ${order.status.label}'),
                      trailing: _StatusBadge(status: order.status),
                      onTap: () async {
                        await Get.to(() => OrderWeighingScreen(orderId: order.id));
                        controller.reload();
                      },
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  Color get _color {
    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.label, style: TextStyle(color: _color, fontWeight: FontWeight.bold)),
    );
  }
}
