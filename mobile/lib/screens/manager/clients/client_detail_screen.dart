import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../models/client.dart';
import '../../../models/order.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
import 'client_detail_controller.dart';

class ClientDetailScreen extends StatelessWidget {
  ClientDetailScreen({super.key, required this.client});

  final Client client;
  late final ClientDetailController controller = Get.put(
    ClientDetailController(Get.find<OrdersRepository>(), client.id),
    tag: 'client_detail_${client.id}',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.cream,
      appBar: AppBar(title: Text(client.name)),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        if (controller.errorMessage.value != null) {
          return ErrorView(message: controller.errorMessage.value!, onRetry: controller.load);
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TicketCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClientAvatar(name: client.name, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              Text(
                                'Всего заказано: ${controller.totalSpent.toStringAsFixed(0)} сом',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (client.phone != null || client.address != null) ...[
                      const Divider(height: 24),
                      if (client.phone != null) _InfoRow(icon: Icons.phone_outlined, text: client.phone!),
                      if (client.address != null)
                        _InfoRow(icon: Icons.location_on_outlined, text: client.address!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('История заказов', style: headingStyle()),
              const SizedBox(height: 10),
              if (controller.orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Заказов пока не было.', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                )
              else
                ...controller.orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TicketCard(
                      accentColor: orderStatusColor(order.status),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '№${order.id} · ${order.deliveryDate.toLocal().toString().split(' ').first}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${order.items.length} поз. · ${order.totalAmount.toStringAsFixed(0)} сом',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          StampBadge(label: order.status.label, color: orderStatusColor(order.status)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BrandColors.redDark),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
