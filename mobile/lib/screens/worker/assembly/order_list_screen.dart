import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/excel_export.dart';
import '../../../core/formatting.dart';
import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/orders_summary_bar.dart';
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
      appBar: AppBar(
        title: const Text('Сборка заказов'),
        actions: [
          Obx(() => _ExportExcelButton(
                date: controller.selectedDate.value,
                repository: Get.find<OrdersRepository>(),
              )),
        ],
      ),
      body: Column(
        children: [
          Obx(() => StaleDataBanner(
                status: controller.dataStatus.value,
                lastUpdated: controller.lastUpdated.value,
                onRetry: controller.reload,
              )),
          Obx(() => WeekDayPicker(
                selected: controller.selectedDate.value,
                onSelected: controller.showDate,
              )),
          Obx(() => OrdersSummaryBar(
                orderCount: controller.orders.length,
                totalWeightGrams: controller.orders.totalWeightGramsSum,
              )),
          Expanded(
            child: Obx(() {
              final showSkeleton = controller.isLoading.value && controller.orders.isEmpty;
              final Widget content;
              if (showSkeleton) {
                content = const SkeletonCardList(key: ValueKey('skeleton'));
              } else if (controller.orders.isEmpty) {
                content = ErrorView(
                  key: const ValueKey('error'),
                  message: 'На этот день заказов не запланировано.',
                  onRetry: controller.reload,
                );
              } else {
                content = RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: controller.reload,
                  child: ListView.separated(
                    itemCount: controller.orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = controller.orders[index];
                      final clientName = order.clientName ?? 'Клиент №${order.clientId}';
                      return StaggeredFadeIn(
                        index: index,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          leading: Hero(
                            tag: 'order-avatar-${order.id}',
                            child: ClientAvatar(name: clientName),
                          ),
                          title: Text(clientName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${itemsCountRu(order.items.length)} · ${formatQtyLabel(order.totalQty, 'шт')}'),
                          trailing: StampBadge(
                            label: order.status.label,
                            color: orderStatusColor(order.status),
                          ),
                          onTap: () async {
                            await Get.to(() => OrderWeighingScreen(orderId: order.id));
                            controller.reload();
                          },
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
    );
  }
}

/// Exports the selected day's orders/summary to .xlsx and opens the share
/// sheet. Self-contained (own loading state + error surface) since it's a
/// one-off action, not something the screen's controller needs to track.
class _ExportExcelButton extends StatefulWidget {
  const _ExportExcelButton({required this.date, required this.repository});

  final DateTime date;
  final OrdersRepository repository;

  @override
  State<_ExportExcelButton> createState() => _ExportExcelButtonState();
}

class _ExportExcelButtonState extends State<_ExportExcelButton> {
  bool _isExporting = false;

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      await ExcelExportService.exportDay(
        repository: widget.repository,
        date: widget.date,
        dateKey: DateFormat('yyyy-MM-dd').format(widget.date),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось выгрузить файл. Проверьте связь.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExporting) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    return IconButton(
      tooltip: 'Выгрузить в Excel',
      icon: const Icon(Icons.ios_share),
      onPressed: _export,
    );
  }
}
