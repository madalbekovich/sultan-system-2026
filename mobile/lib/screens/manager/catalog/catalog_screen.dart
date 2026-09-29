import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
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
      appBar: AppBar(title: const Text('Каталог товаров')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductFormSheet(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Obx(() => controller.isOffline.value ? const OfflineBanner() : const SizedBox.shrink()),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const LoadingView();
              }
              if (controller.products.isEmpty) {
                return ErrorView(message: 'Пока нет товаров.', onRetry: controller.reload);
              }
              return RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.separated(
                  itemCount: controller.products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = controller.products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${controller.categoryName(product.categoryId)} · ${product.pricePerUnit}/${product.unitType.label}',
                      ),
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
