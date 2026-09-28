import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../data/orders_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_views.dart';
import 'production_summary_controller.dart';

class ProductionSummaryScreen extends StatelessWidget {
  const ProductionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => ProductionSummaryController(Get.find<OrdersRepository>()),
      tag: 'production_summary',
    )..refresh(silent: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Weight Needed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Order assembly',
            onPressed: () => Get.toNamed(AppRoutes.workerAssembly),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => controller.isOffline.value ? const OfflineBanner() : const SizedBox.shrink()),
          _DateTabs(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.summary.value == null) {
                return const LoadingView();
              }
              final summary = controller.summary.value;
              if (summary == null) {
                return ErrorView(
                  message: 'No data yet. Pull to refresh once online.',
                  onRetry: controller.refresh,
                );
              }
              if (summary.products.isEmpty) {
                return const Center(child: Text('No orders for this day yet.'));
              }
              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: summary.products.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final entry = summary.products[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.productName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${entry.clientCount} client${entry.clientCount == 1 ? '' : 's'}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.totalPlannedQty} ${entry.unitType.toLowerCase()}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
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

class _DateTabs extends StatelessWidget {
  const _DateTabs({required this.controller});

  final ProductionSummaryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final now = DateTime.now();
      final isToday = controller.selectedDate.value.day == now.day &&
          controller.selectedDate.value.month == now.month;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Today', style: TextStyle(fontSize: 16)),
                selected: isToday,
                onSelected: (_) => controller.showToday(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Tomorrow', style: TextStyle(fontSize: 16)),
                selected: !isToday,
                onSelected: (_) => controller.showTomorrow(),
              ),
            ),
          ],
        ),
      );
    });
  }
}
