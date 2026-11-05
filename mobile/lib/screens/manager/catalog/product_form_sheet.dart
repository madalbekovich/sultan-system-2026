import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';

/// Pass [existing] to edit a product in place; omit it to create a new
/// one. Decoupled from any specific controller — [categories] and the
/// create/edit callbacks are passed in, so this one form works both from
/// the catalog screen and from a warehouse's price-sheet screen (adding a
/// product there adds it to the one shared catalog, same as everywhere
/// else — there's no per-warehouse product list, only per-warehouse
/// prices).
Future<void> showProductFormSheet(
  BuildContext context, {
  required List<Category> categories,
  required Future<bool> Function(Product product) onCreate,
  required Future<bool> Function(Product existing, Map<String, dynamic> changes) onEdit,
  Product? existing,
}) {
  final isEditing = existing != null;
  final nameController = TextEditingController(text: existing?.name ?? '');
  final priceController =
      TextEditingController(text: existing != null ? existing.pricePerUnit.toString() : '');
  final weightController = TextEditingController(
      text: existing?.weightGrams != null ? existing!.weightGrams.toString() : '');
  int? categoryId =
      existing?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
  UnitType unitType = existing?.unitType ?? UnitType.kg;

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
                items: categories
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
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Вес единицы, г (необязательно)',
                ),
                keyboardType: TextInputType.number,
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
                    final weightGrams = int.tryParse(weightController.text.trim());
                    final success = isEditing
                        ? await onEdit(existing, {
                            'name': nameController.text.trim(),
                            'category_id': categoryId,
                            'price_per_unit': price,
                            'unit_type': unitType == UnitType.pcs ? 'PCS' : 'KG',
                            'weight_grams': weightGrams,
                          })
                        : await onCreate(
                            Product(
                              id: 0,
                              categoryId: categoryId!,
                              name: nameController.text.trim(),
                              unitType: unitType,
                              pricePerUnit: price,
                              isActive: true,
                              weightGrams: weightGrams,
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
