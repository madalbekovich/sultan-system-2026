import 'package:get/get.dart';

import '../../../data/products_repository.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';

class CatalogController extends GetxController {
  CatalogController(this._repository);

  final ProductsRepository _repository;

  final products = <Product>[].obs;
  final categories = <Category>[].obs;
  final isLoading = true.obs;
  final isOffline = false.obs;

  @override
  void onInit() {
    super.onInit();
    products.assignAll(_repository.cachedProducts());
    categories.assignAll(_repository.cachedCategories());
    isLoading.value = products.isEmpty;
    reload();
  }

  Future<void> reload() async {
    try {
      final results = await Future.wait([
        _repository.fetchProducts(activeOnly: false),
        _repository.fetchCategories(),
      ]);
      products.assignAll(results[0] as List<Product>);
      categories.assignAll(results[1] as List<Category>);
      isOffline.value = false;
    } catch (_) {
      isOffline.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  String categoryName(int categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return '—';
  }

  Future<void> createProduct(Product product) async {
    final created = await _repository.createProduct(product);
    products.add(created);
  }

  Future<void> toggleActive(Product product) async {
    final updated = await _repository.updateProduct(
      product.id,
      {'is_active': !product.isActive},
    );
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) products[index] = updated;
  }
}
