import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/orders_summary_bar.dart';
import '../../../widgets/skeleton.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const AppHeader(subtitle: 'Сколько нужно взвесить сегодня'),
          Obx(() => StaleDataBanner(
                status: controller.dataStatus.value,
                lastUpdated: controller.lastUpdated.value,
                onRetry: controller.reload,
              )),
          Obx(() => WeekDayPicker(
                selected: controller.selectedDate.value,
                onSelected: controller.showDate,
              )),
          Obx(() {
            final summary = controller.summary.value;
            return OrdersSummaryBar(
              orderCount: summary?.orderCount ?? 0,
              totalWeightGrams: summary?.totalWeightGrams ?? 0,
            );
          }),
          Expanded(
            child: Obx(() {
              final showSkeleton = controller.isLoading.value && controller.summary.value == null;
              final summary = controller.summary.value;
              final Widget content;
              if (showSkeleton) {
                content = const SkeletonCardList(key: ValueKey('skeleton'));
              } else if (summary == null) {
                content = ErrorView(
                  key: const ValueKey('error'),
                  message: 'Пока нет данных. Потяните вниз, чтобы обновить.',
                  onRetry: controller.reload,
                );
              } else if (summary.products.isEmpty) {
                content = const Center(
                  key: ValueKey('empty'),
                  child: Text('На этот день заказов пока нет.'),
                );
              } else {
                content = RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: controller.reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: summary.products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + 2),
                    itemBuilder: (context, index) {
                      final entry = summary.products[index];
                      final (icon, color) = productVisual(entry.productName);
                      return StaggeredFadeIn(
                        index: index,
                        child: TicketCard(
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
                              const SizedBox(width: AppSpacing.md + 2),
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
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatQtyLabel(entry.totalPlannedQty, unitLabelRu(entry.unitType)),
                                style: numberStyle(fontSize: 21, color: AppColors.redDark),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: AppCurves.enter,
                child: content,
              );
            }),
          ),
        ],
      ),
      ),
    );
  }
}
