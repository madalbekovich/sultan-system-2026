import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
import '../catalog/catalog_screen.dart';
import '../clients/clients_screen.dart';
import '../orders/manager_orders_screen.dart';
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
        title: const Text('Руководитель'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Заказы',
            onPressed: () => Get.to(() => const ManagerOrdersScreen()),
          ),
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
                      onTap: () => Get.to(() => const ManagerOrdersScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Вес по товарам', style: headingStyle()),
              const SizedBox(height: 10),
              ...?controller.summary.value?.products.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TicketCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                clientsCountRu(entry.clientCount),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.totalPlannedQty} ${unitLabelRu(entry.unitType)}',
                          style: numberStyle(fontSize: 17),
                        ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: numberStyle(fontSize: 26, color: color)),
        ],
      ),
    );
  }
}
