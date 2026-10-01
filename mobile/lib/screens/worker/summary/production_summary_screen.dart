import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
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
    )..reload(silent: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сколько всего нужно'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Сборка заказов',
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
                  message: 'Пока нет данных. Потяните вниз, чтобы обновить.',
                  onRetry: controller.reload,
                );
              }
              if (summary.products.isEmpty) {
                return const Center(child: Text('На этот день заказов пока нет.'));
              }
              return RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: summary.products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = summary.products[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: BrandColors.yellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.scale, color: BrandColors.black, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.productName,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  clientsCountRu(entry.clientCount),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${entry.totalPlannedQty} ${unitLabelRu(entry.unitType)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.redDark,
                            ),
                          ),
                        ],
                      ),
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
                label: const Text('Сегодня', style: TextStyle(fontSize: 16)),
                selected: isToday,
                onSelected: (_) => controller.showToday(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Завтра', style: TextStyle(fontSize: 16)),
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
