import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../models/client.dart';
import '../../../models/order.dart';
import '../../../widgets/status_views.dart';
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (client.phone != null)
                      _InfoRow(icon: Icons.phone, text: client.phone!),
                    if (client.address != null)
                      _InfoRow(icon: Icons.location_on_outlined, text: client.address!),
                    _InfoRow(
                      icon: Icons.payments_outlined,
                      text: 'Всего заказано: ${controller.totalSpent.toStringAsFixed(0)} сом',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('История заказов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (controller.orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Заказов пока не было.')),
                )
              else
                ...controller.orders.map(
                  (order) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('№${order.id} · ${order.deliveryDate.toLocal().toString().split(' ').first}'),
                      subtitle: Text('${order.items.length} поз. · ${order.status.label}'),
                      trailing: Text(
                        '${order.totalAmount.toStringAsFixed(0)} сом',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
