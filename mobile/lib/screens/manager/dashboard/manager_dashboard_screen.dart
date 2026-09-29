import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../data/orders_repository.dart';
import '../../../widgets/status_views.dart';
import '../catalog/catalog_screen.dart';
import '../clients/clients_screen.dart';
import '../waybill/waybill_screen.dart';
import 'manager_dashboard_controller.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => ManagerDashboardController(Get.find<OrdersRepository>()),
      tag: 'manager_dashboard',
    )..reload();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            tooltip: 'Catalog',
            onPressed: () => Get.to(() => const CatalogScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Clients',
            onPressed: () => Get.to(() => const ClientsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Waybill',
            onPressed: () => Get.to(() => const WaybillScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.summary.value == null) {
          return const LoadingView();
        }
        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.isOffline.value) const OfflineBanner(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: "Today's sales",
                      value: controller.totalSalesToday.toStringAsFixed(0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Dispatched',
                      value:
                          '${controller.dispatchedCount}/${controller.todaysOrders.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Weight by product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...?controller.summary.value?.products.map(
                (entry) => ListTile(
                  title: Text(entry.productName),
                  subtitle: Text('${entry.clientCount} clients'),
                  trailing: Text(
                    '${entry.totalPlannedQty} ${entry.unitType.toLowerCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
