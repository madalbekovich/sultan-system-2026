import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      backgroundColor: BrandColors.cream,
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClientAvatar(name: clientName, size: 40),
                  const SizedBox(width: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) => _WeighingRow(
                  item: order.items[index],
                  onSubmit: (qty) => controller.submitWeight(order.items[index].id, qty),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Итого', style: TextStyle(fontSize: 20)),
                      Text(
                        controller.liveTotal.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (order.status == OrderStatus.dispatched)
                    const BigButton(
                      label: 'Отправлен ✓',
                      icon: Icons.local_shipping,
                      color: Colors.blue,
                      onPressed: null,
                    )
                  else if (order.status == OrderStatus.ready) ...[
                    const BigButton(
                      label: 'Готов к отгрузке ✓',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onPressed: null,
                    ),
                    const SizedBox(height: 12),
                    BigButton(
                      label: 'Отметить как отправленный',
                      icon: Icons.local_shipping,
                      onPressed: controller.markDispatched,
                    ),
                  ] else
                    BigButton(
                      label: 'Отметить как собранный / готовый',
                      icon: Icons.check_circle,
                      onPressed: controller.markReady,
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
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                productName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('План: ${item.plannedQty}', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  labelText: 'Фактический вес',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 12),
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
    widget.onSubmit(value);
  }
}
