import 'package:flutter/material.dart';

import '../../../models/product.dart';
import 'catalog_controller.dart';

Future<void> showProductFormSheet(BuildContext context, CatalogController controller) {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  int? categoryId = controller.categories.isNotEmpty ? controller.categories.first.id : null;
  UnitType unitType = UnitType.kg;

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
              const Text('New product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
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
                      decoration: const InputDecoration(labelText: 'Price per unit'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<UnitType>(
                    value: unitType,
                    items: const [
                      DropdownMenuItem(value: UnitType.kg, child: Text('kg')),
                      DropdownMenuItem(value: UnitType.pcs, child: Text('pcs')),
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
                    await controller.createProduct(
                      Product(
                        id: 0,
                        categoryId: categoryId!,
                        name: nameController.text.trim(),
                        unitType: unitType,
                        pricePerUnit: price,
                        isActive: true,
                      ),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
