import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/week_day_picker.dart';
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
                    final clientName = order.clientName ?? 'Клиент №${order.clientId}';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      leading: ClientAvatar(name: clientName),
                      title: Text(clientName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      subtitle: Text(itemsCountRu(order.items.length)),
                      trailing: StampBadge(
                        label: order.status.label,
                        color: orderStatusColor(order.status),
                      ),
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
