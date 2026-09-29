import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../core/api_client.dart';
import '../../../data/orders_repository.dart';

class WaybillScreen extends StatefulWidget {
  const WaybillScreen({super.key});

  @override
  State<WaybillScreen> createState() => _WaybillScreenState();
}

class _WaybillScreenState extends State<WaybillScreen> {
  final _orderIdController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Накладная')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _orderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Номер заказа',
                    hintText: 'например, 42',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                if (_isLoading) const CircularProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (!_isLoading) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Предпросмотр / Печать'),
                      onPressed: () => _withBytes((bytes) => Printing.layoutPdf(
                            onLayout: (_) async => Uint8List.fromList(bytes),
                          )),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Отправить (WhatsApp и т.д.)'),
                      onPressed: () => _withBytes((bytes) => Printing.sharePdf(
                            bytes: Uint8List.fromList(bytes),
                            filename: 'waybill-${_orderIdController.text.trim()}.pdf',
                          )),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _withBytes(Future<void> Function(List<int> bytes) action) async {
    final orderId = int.tryParse(_orderIdController.text.trim());
    if (orderId == null) {
      setState(() => _error = 'Введите корректный номер заказа.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bytes = await Get.find<OrdersRepository>().fetchWaybillPdf(orderId);
      await action(bytes);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Не удалось получить накладную.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
