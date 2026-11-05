import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/get_utils.dart';
import '../../../core/theme.dart';
import '../../../data/products_repository.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/skeleton.dart';
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
        onPressed: () => showProductFormSheet(
          context,
          categories: controller.categories,
          onCreate: controller.createProduct,
          onEdit: controller.editProduct,
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Obx(() => StaleDataBanner(
                status: controller.dataStatus.value,
                lastUpdated: controller.lastUpdated.value,
                onRetry: controller.reload,
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Поиск товара…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
            child: Obx(() => Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Без своей цены у складов'),
                    selected: controller.showOnlyMissingPrice.value,
                    onSelected: (v) => controller.showOnlyMissingPrice.value = v,
                  ),
                )),
          ),
          Expanded(
            child: Obx(() {
              final showSkeleton =
                  controller.isLoading.value && controller.products.isEmpty;
              final items = controller.filteredProducts;
              final Widget content;
              if (showSkeleton) {
                content = const SkeletonCardList(
                  key: ValueKey('skeleton'),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                );
              } else if (items.isEmpty) {
                content = ErrorView(
                  key: const ValueKey('error'),
                  message: controller.products.isEmpty
                      ? 'Пока нет товаров.'
                      : 'Ничего не найдено.',
                  onRetry: controller.reload,
                );
              } else {
                content = RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: controller.reload,
                  child: ListView.separated(
                    // FAB diameter (56) + 24 clearance + the device's own
                    // bottom safe-area inset (home indicator / gesture bar),
                    // so the last row never sits under the FAB.
                    padding: EdgeInsets.only(
                        bottom: 80 + MediaQuery.of(context).padding.bottom),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      final categoryName =
                          controller.categoryName(product.categoryId);
                      final (icon, color) = productVisual(categoryName);
                      return StaggeredFadeIn(
                        index: index,
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          title: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Builder(builder: (context) {
                            final coverage = controller.priceCoverage[product.id];
                            final missingText = coverage != null && coverage.clientsMissing > 0
                                ? ' · у ${coverage.clientsMissing} складов нет своей цены'
                                : '';
                            return Text(
                              '$categoryName · ${formatPricePerUnit(product.pricePerUnit, product.unitType)}$missingText',
                              style: missingText.isNotEmpty
                                  ? const TextStyle(color: AppColors.ochre)
                                  : null,
                            );
                          }),
                          onTap: () => showProductFormSheet(
                            context,
                            categories: controller.categories,
                            onCreate: controller.createProduct,
                            onEdit: controller.editProduct,
                            existing: product,
                          ),
                          trailing: Switch(
                            value: product.isActive,
                            onChanged: (_) {
                              HapticFeedback.lightImpact();
                              controller.toggleActive(product);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: AppCurves.enter,
                child: content,
              );
            }),
          ),
        ],
      ),
    );
  }
}
