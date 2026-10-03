import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/theme.dart';
import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/big_button.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/status_views.dart';
import 'order_weighing_controller.dart';

class OrderWeighingScreen extends StatelessWidget {
  OrderWeighingScreen({super.key, required this.orderId});

  final int orderId;
  late final OrderWeighingController controller = Get.put(
    OrderWeighingController(Get.find<OrdersRepository>(), orderId),
    tag: 'weighing_$orderId',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Взвешивание')),
      body: Obx(() {
        if (controller.isLoading.value && controller.order.value == null) {
          return const LoadingView();
        }
        final order = controller.order.value;
        if (order == null) {
          return ErrorView(message: controller.errorMessage.value ?? 'Заказ не найден.');
        }
        final clientName = order.clientName ?? 'Клиент №${order.clientId}';
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Hero(
                    tag: 'order-avatar-$orderId',
                    child: ClientAvatar(name: clientName, size: 40),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const Divider(height: AppSpacing.xxl),
                itemBuilder: (context, index) => _WeighingRow(
                  item: order.items[index],
                  onSubmit: (qty) => controller.submitWeight(order.items[index].id, qty),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Итого', style: TextStyle(fontSize: 20)),
                      Text(
                        formatMoney(controller.liveTotal),
                        style: numberStyle(fontSize: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (order.status == OrderStatus.dispatched)
                    const BigButton(
                      label: 'Отправлен ✓',
                      icon: Icons.local_shipping,
                      color: AppColors.statusDispatched,
                      onPressed: null,
                    )
                  else if (order.status == OrderStatus.ready) ...[
                    const BigButton(
                      label: 'Готов к отгрузке ✓',
                      icon: Icons.check_circle,
                      color: AppColors.statusReady,
                      onPressed: null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BigButton(
                      label: 'Отметить как отправленный',
                      icon: Icons.local_shipping,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        controller.markDispatched();
                      },
                    ),
                  ] else
                    BigButton(
                      label: 'Отметить как собранный / готовый',
                      icon: Icons.check_circle,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        controller.markReady();
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _WeighingRow extends StatefulWidget {
  const _WeighingRow({required this.item, required this.onSubmit});

  final OrderItem item;
  final void Function(double qty) onSubmit;

  @override
  State<_WeighingRow> createState() => _WeighingRowState();
}

class _WeighingRowState extends State<_WeighingRow> {
  late final TextEditingController _qtyController = TextEditingController(
    text: (widget.item.actualQty ?? widget.item.plannedQty).toString(),
  );

  @override
  void didUpdateWidget(covariant _WeighingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _qtyController.text = (widget.item.actualQty ?? widget.item.plannedQty).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productName = item.productName ?? 'Товар №${item.productId}';
    final (icon, color) = productVisual(productName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                productName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('План: ${item.plannedQty}', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  labelText: 'Фактический вес',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton.filled(
              iconSize: 32,
              onPressed: _submit,
              icon: const Icon(Icons.check),
            ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    final value = double.tryParse(_qtyController.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) return;
    HapticFeedback.lightImpact();
    widget.onSubmit(value);
  }
}
