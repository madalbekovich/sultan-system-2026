import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/orders_repository.dart';
import '../../../models/order.dart';
import '../../../widgets/big_button.dart';
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
      appBar: AppBar(title: const Text('Weigh & Assemble')),
      body: Obx(() {
        if (controller.isLoading.value && controller.order.value == null) {
          return const LoadingView();
        }
        final order = controller.order.value;
        if (order == null) {
          return ErrorView(message: controller.errorMessage.value ?? 'Order not found.');
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                order.clientName ?? 'Client #${order.clientId}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      const Text('Total', style: TextStyle(fontSize: 20)),
                      Text(
                        controller.liveTotal.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BigButton(
                    label: order.status == OrderStatus.ready
                        ? 'Ready for shipping ✓'
                        : 'Mark Assembled / Ready for Shipping',
                    icon: Icons.check_circle,
                    color: order.status == OrderStatus.ready ? Colors.green : null,
                    onPressed: order.status == OrderStatus.ready ? null : controller.markReady,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.productName ?? 'Product #${item.productId}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text('Planned: ${item.plannedQty}', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  labelText: 'Actual weighed qty',
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
