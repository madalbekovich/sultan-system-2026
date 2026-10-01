import 'package:flutter/material.dart';

import '../../../models/product.dart';
import 'catalog_controller.dart';

/// Pass [existing] to edit a product in place; omit it to create a new one.
Future<void> showProductFormSheet(
  BuildContext context,
  CatalogController controller, {
  Product? existing,
}) {
  final isEditing = existing != null;
  final nameController = TextEditingController(text: existing?.name ?? '');
  final priceController =
      TextEditingController(text: existing != null ? existing.pricePerUnit.toString() : '');
  int? categoryId =
      existing?.categoryId ?? (controller.categories.isNotEmpty ? controller.categories.first.id : null);
  UnitType unitType = existing?.unitType ?? UnitType.kg;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Редактировать товар' : 'Новый товар',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: controller.categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (value) => setState(() => categoryId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Цена за единицу'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<UnitType>(
                    value: unitType,
                    items: const [
                      DropdownMenuItem(value: UnitType.kg, child: Text('кг')),
                      DropdownMenuItem(value: UnitType.pcs, child: Text('шт')),
                    ],
                    onChanged: (value) => setState(() => unitType = value ?? UnitType.kg),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final price = double.tryParse(priceController.text.trim().replaceAll(',', '.'));
                    if (nameController.text.trim().isEmpty || price == null || categoryId == null) {
                      return;
                    }
                    final success = isEditing
                        ? await controller.editProduct(existing, {
                            'name': nameController.text.trim(),
                            'category_id': categoryId,
                            'price_per_unit': price,
                            'unit_type': unitType == UnitType.pcs ? 'PCS' : 'KG',
                          })
                        : await controller.createProduct(
                            Product(
                              id: 0,
                              categoryId: categoryId!,
                              name: nameController.text.trim(),
                              unitType: unitType,
                              pricePerUnit: price,
                              isActive: true,
                            ),
                          );
                    if (success && context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
