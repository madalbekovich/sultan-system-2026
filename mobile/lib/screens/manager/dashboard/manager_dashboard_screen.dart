import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/get_utils.dart';
import '../../../core/refresh_status.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/sales_bar_chart.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: AppColors.cream,
      body: Obx(() {
        final showSkeleton = controller.isLoading.value && controller.analytics.value == null;
        if (showSkeleton) {
          return AnimatedSwitcher(
            duration: AppDurations.medium,
            switchInCurve: AppCurves.enter,
            child: ListView(
              key: const ValueKey('skeleton'),
              padding: EdgeInsets.zero,
              children: [
                AppHeader(subtitle: formattedToday()),
                const SkeletonCardList(count: 6),
              ],
            ),
          );
        }
        final analytics = controller.analytics.value;
        return AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: AppCurves.enter,
          child: RefreshIndicator(
          key: const ValueKey('content'),
          onRefresh: controller.reload,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AppHeader(
                subtitle: formattedToday(),
                action: IconButton(
                  onPressed: () => Get.to(() => const WaybillScreen()),
                  icon: const Icon(Icons.description_outlined, color: Colors.white),
                  tooltip: 'Накладная',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.dataStatus.value != DataStatus.ok)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: StaleDataBanner(
                          status: controller.dataStatus.value,
                          lastUpdated: controller.lastUpdated.value,
                          onRetry: controller.reload,
                        ),
                      ),

                    // KPI grid
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Продажи сегодня',
                            value: formatMoneyNumber(controller.totalSalesToday),
                            suffix: 'сом',
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: _StatCard(
                            label: 'Заказов сегодня',
                            value: controller.todaysOrders.length.toString(),
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Средний чек',
                            value: formatMoneyNumber(controller.averageOrderValue),
                            suffix: 'сом',
                            icon: Icons.calculate_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: _StatCard(
                            label: 'Отгружено',
                            value: '${controller.dispatchedCount}/${controller.todaysOrders.length}',
                            icon: Icons.local_shipping_outlined,
                            onTap: () => Get.to(() => const ManagerOrdersScreen()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl - 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Продажи за неделю', style: headingStyle()),
                        if (analytics != null)
                          Text(
                            formatMoney(analytics.dailySales.fold<double>(0, (s, d) => s + d.totalAmount)),
                            style: numberStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md + 2),
                    TicketCard(
                      child: analytics == null
                          ? const SizedBox(height: 140)
                          : SalesBarChart(data: analytics.dailySales),
                    ),

                    const SizedBox(height: AppSpacing.xxl - 4),
                    Text('Топ товары за неделю', style: headingStyle()),
                    const SizedBox(height: AppSpacing.sm + 2),
                    if (analytics != null && analytics.topProducts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text('Пока нет заказов за этот период.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ...?analytics?.topProducts.asMap().entries.map(
                      (indexed) {
                        final entry = indexed.value;
                        final (icon, color) = productVisual(entry.productName);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: StaggeredFadeIn(
                            index: indexed.key,
                            child: TicketCard(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Icon(icon, color: color, size: 17),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(
                                          clientsCountRu(entry.clientCount),
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatQtyLabel(entry.totalPlannedQty, unitLabelRu(entry.unitType)),
                                    style: numberStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xxl - 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Последние заказы', style: headingStyle()),
                        TextButton(
                          onPressed: () => Get.to(() => const ManagerOrdersScreen()),
                          child: const Text('Все заказы'),
                        ),
                      ],
                    ),
                    ...?analytics?.recentOrders.asMap().entries.map(
                      (indexed) {
                        final order = indexed.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: StaggeredFadeIn(
                            index: indexed.key,
                            child: TicketCard(
                              accentColor: orderStatusColor(order.status),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 2),
                              child: Row(
                                children: [
                                  ClientAvatar(name: order.clientName ?? 'Клиент №${order.clientId}', size: 36),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.clientName ?? 'Клиент №${order.clientId}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '№${order.id} · ${formatMoney(order.totalAmount)}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StampBadge(label: order.status.label, color: orderStatusColor(order.status)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      }),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2, vertical: AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: numberStyle(fontSize: 22)),
              if (suffix != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(suffix!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
