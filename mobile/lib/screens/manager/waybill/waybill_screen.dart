import 'package:flutter/material.dart';

import '../../../core/waybill_actions.dart';

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
      appBar: AppBar(title: const Text('НАКЛАДНАЯ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
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
                        onPressed: () => _run(WaybillActions.print),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Отправить (WhatsApp и т.д.)'),
                        onPressed: () => _run(WaybillActions.share),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _run(Future<String?> Function(int orderId) action) async {
    final orderId = int.tryParse(_orderIdController.text.trim());
    if (orderId == null) {
      setState(() => _error = 'Введите корректный номер заказа.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final error = await action(orderId);
    setState(() {
      _error = error;
      _isLoading = false;
    });
  }
}
