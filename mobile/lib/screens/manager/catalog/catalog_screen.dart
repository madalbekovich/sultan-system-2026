import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../core/theme.dart';
import '../../../data/products_repository.dart';
import '../../../models/product.dart';
import '../../../widgets/status_views.dart';
import 'catalog_controller.dart';
import 'product_form_sheet.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => CatalogController(Get.find<ProductsRepository>()),
      tag: 'catalog',
    )..reload();

    return Scaffold(
      appBar: AppBar(title: const Text('Каталог')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductFormSheet(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Obx(() => controller.isOffline.value ? const OfflineBanner() : const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Поиск товара…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const LoadingView();
              }
              final items = controller.filteredProducts;
              if (items.isEmpty) {
                return ErrorView(
                  message: controller.products.isEmpty
                      ? 'Пока нет товаров.'
                      : 'Ничего не найдено.',
                  onRetry: controller.reload,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    final categoryName = controller.categoryName(product.categoryId);
                    final (icon, color) = productVisual(categoryName);
                    return ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      title: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('$categoryName · ${product.pricePerUnit}/${product.unitType.label}'),
                      onTap: () => showProductFormSheet(context, controller, existing: product),
                      trailing: Switch(
                        value: product.isActive,
                        onChanged: (_) => controller.toggleActive(product),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
