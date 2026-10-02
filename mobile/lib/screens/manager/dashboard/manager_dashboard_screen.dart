import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/get_utils.dart';
import '../../../core/ru_text.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/brand_logo.dart';
import '../../../widgets/sales_bar_chart.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
import '../orders/manager_orders_screen.dart';
import '../waybill/waybill_screen.dart';
import 'manager_dashboard_controller.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 5) return 'Доброй ночи';
  if (hour < 12) return 'Доброе утро';
  if (hour < 18) return 'Добрый день';
  return 'Добрый вечер';
}

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => ManagerDashboardController(Get.find<OrdersRepository>()),
      tag: 'manager_dashboard',
    )..reload();

    return Scaffold(
      backgroundColor: BrandColors.cream,
      body: Obx(() {
        if (controller.isLoading.value && controller.analytics.value == null) {
          return const LoadingView();
        }
        final analytics = controller.analytics.value;
        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(onWaybillTap: () => Get.to(() => const WaybillScreen())),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.isOffline.value)
                      const Padding(padding: EdgeInsets.only(bottom: 12), child: OfflineBanner()),

                    // KPI grid
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Продажи сегодня',
                            value: controller.totalSalesToday.toStringAsFixed(0),
                            suffix: 'сом',
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Заказов сегодня',
                            value: controller.todaysOrders.length.toString(),
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Средний чек',
                            value: controller.averageOrderValue.toStringAsFixed(0),
                            suffix: 'сом',
                            icon: Icons.calculate_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
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

                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Продажи за неделю', style: headingStyle()),
                        if (analytics != null)
                          Text(
                            '${analytics.dailySales.fold<double>(0, (s, d) => s + d.totalAmount).toStringAsFixed(0)} сом',
                            style: numberStyle(fontSize: 14, color: Colors.black54),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TicketCard(
                      child: analytics == null
                          ? const SizedBox(height: 140)
                          : SalesBarChart(data: analytics.dailySales),
                    ),

                    const SizedBox(height: 28),
                    Text('Топ товары за неделю', style: headingStyle()),
                    const SizedBox(height: 10),
                    if (analytics != null && analytics.topProducts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Пока нет заказов за этот период.',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ),
                    ...?analytics?.topProducts.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TicketCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Builder(builder: (context) {
                            final (icon, color) = productVisual(entry.productName);
                            return Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(icon, color: color, size: 17),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(
                                        clientsCountRu(entry.clientCount),
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${entry.totalPlannedQty} ${unitLabelRu(entry.unitType)}',
                                  style: numberStyle(fontSize: 16),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
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
                    ...?analytics?.recentOrders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TicketCard(
                          accentColor: orderStatusColor(order.status),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.clientName ?? 'Клиент №${order.clientId}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '№${order.id} · ${order.totalAmount.toStringAsFixed(0)} сом',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              StampBadge(label: order.status.label, color: orderStatusColor(order.status)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onWaybillTap});

  final VoidCallback onWaybillTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.graphite, BrandColors.black],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 24),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const BrandLogo(size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      intl.DateFormat('EEEE, d MMMM', 'ru').format(DateTime.now()),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onWaybillTap,
                icon: const Icon(Icons.description_outlined, color: Colors.white),
                tooltip: 'Накладная',
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: numberStyle(fontSize: 22)),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(suffix!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
