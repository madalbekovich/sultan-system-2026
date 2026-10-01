import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
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
        title: const Text('Панель руководителя'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            tooltip: 'Каталог',
            onPressed: () => Get.to(() => const CatalogScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Клиенты',
            onPressed: () => Get.to(() => const ClientsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Накладная',
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
                      label: 'Продажи за сегодня',
                      value: controller.totalSalesToday.toStringAsFixed(0),
                      icon: Icons.payments_rounded,
                      color: BrandColors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Отгружено',
                      value:
                          '${controller.dispatchedCount}/${controller.todaysOrders.length}',
                      icon: Icons.local_shipping_rounded,
                      color: BrandColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 20,
                    decoration: BoxDecoration(
                      color: BrandColors.yellow,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Вес по товарам', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ...?controller.summary.value?.products.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: BrandColors.cream,
                      child: Icon(Icons.inventory_2_outlined, color: BrandColors.redDark),
                    ),
                    title: Text(entry.productName),
                    subtitle: Text(clientsCountRu(entry.clientCount)),
                    trailing: Text(
                      '${entry.totalPlannedQty} ${unitLabelRu(entry.unitType)}',
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
