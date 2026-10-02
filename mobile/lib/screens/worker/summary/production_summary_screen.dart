import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
import '../../../widgets/week_day_picker.dart';
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
      backgroundColor: BrandColors.cream,
      body: Column(
        children: [
          const AppHeader(subtitle: 'Сколько нужно взвесить сегодня'),
          Obx(() => controller.isOffline.value ? const OfflineBanner() : const SizedBox.shrink()),
          Obx(() => WeekDayPicker(
                selected: controller.selectedDate.value,
                onSelected: controller.showDate,
              )),
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
                    final (icon, color) = productVisual(entry.productName);
                    return TicketCard(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.productName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                            style: numberStyle(fontSize: 21, color: BrandColors.redDark),
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
