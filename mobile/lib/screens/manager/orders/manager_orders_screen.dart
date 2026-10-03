import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../core/waybill_actions.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
import '../../../widgets/week_day_picker.dart';
import 'manager_orders_controller.dart';

class ManagerOrdersScreen extends StatelessWidget {
  const ManagerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => ManagerOrdersController(Get.find<OrdersRepository>()),
      tag: 'manager_orders',
    )..reload();

    return Scaffold(
      appBar: AppBar(title: const Text('Заказы')),
      body: Column(
        children: [
          Obx(() => controller.isOffline.value ? const OfflineBanner() : const SizedBox.shrink()),
          Obx(() => WeekDayPicker(
                selected: controller.selectedDate.value,
                onSelected: controller.showDate,
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
                  message: 'На этот день заказов нет.',
                  onRetry: controller.reload,
                );
              } else {
                content = RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: controller.reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: controller.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md + 2),
                    itemBuilder: (context, index) {
                      final order = controller.orders[index];
                      return StaggeredFadeIn(
                        index: index,
                        child: _OrderCard(
                          order: order,
                          isUpdating: controller.updatingOrderIds.contains(order.id),
                          onStatusChange: (status) {
                            HapticFeedback.selectionClick();
                            controller.changeStatus(order, status);
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isUpdating,
    required this.onStatusChange,
  });

  final Order order;
  final bool isUpdating;
  final void Function(OrderStatus status) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final statusColor = orderStatusColor(order.status);
    final clientName = order.clientName ?? 'Клиент №${order.clientId}';
    return TicketCard(
      accentColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClientAvatar(name: clientName, size: 36),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  clientName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text('№${order.id}', style: numberStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(itemsCountRu(order.items.length), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 2),
          Text(formatMoney(order.totalAmount), style: numberStyle(fontSize: 24, weight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              if (isUpdating)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<OrderStatus>(
                  initialValue: order.status,
                  onSelected: onStatusChange,
                  itemBuilder: (context) => OrderStatus.values
                      .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StampBadge(label: order.status.label, color: statusColor),
                      Icon(Icons.arrow_drop_down, color: statusColor),
                    ],
                  ),
                ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Печать накладной',
                icon: const Icon(Icons.print_outlined, color: AppColors.textMuted, size: 19),
                onPressed: () => WaybillActions.print(order.id),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Отправить накладную',
                icon: const Icon(Icons.share_outlined, color: AppColors.textMuted, size: 19),
                onPressed: () => WaybillActions.share(order.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
