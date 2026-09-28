import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/status_views.dart';
import 'order_list_controller.dart';
import 'order_weighing_screen.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      OrderListController(Get.find<OrdersRepository>()),
      tag: 'order_list',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Order Assembly')),
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
                  message: 'No orders scheduled for this day.',
                  onRetry: controller.refresh,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.separated(
                  itemCount: controller.orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      title: Text(order.clientName ?? 'Client #${order.clientId}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      subtitle: Text('${order.items.length} item(s) · ${order.status.label}'),
                      trailing: _StatusBadge(status: order.status),
                      onTap: () async {
                        await Get.to(() => OrderWeighingScreen(orderId: order.id));
                        controller.refresh();
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
      decoration: BoxDecoration(color: _color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status.label, style: TextStyle(color: _color, fontWeight: FontWeight.bold)),
    );
  }
}
