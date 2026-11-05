import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'clients_controller.dart';

/// New-warehouse form — manager-only. The code and Telegram binding are
/// generated/attached server-side; here the manager only enters the
/// business details and, optionally, picks an existing warehouse whose
/// price sheet to copy as a starting point (per the requirement that a
/// brand-new warehouse shouldn't start from a blank price list).
Future<void> showClientFormSheet(
  BuildContext context,
  ClientsController controller,
) {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  int? copyFromId;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Новый склад', style: headingStyle(fontSize: 18)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Название склада'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Телефон (необязательно)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Адрес (необязательно)'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int?>(
                initialValue: copyFromId,
                decoration: const InputDecoration(labelText: 'Скопировать цены с другого склада'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Не копировать')),
                  ...controller.clients.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text('${c.clientCode} — ${c.name}')),
                  ),
                ],
                onChanged: (value) => setState(() => copyFromId = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final success = await controller.createClient(
                      name: name,
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                      copyPricesFromClientId: copyFromId,
                    );
                    if (success && context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Создать'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
