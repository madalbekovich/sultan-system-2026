import 'package:get/get.dart';

import '../../../core/error_feedback.dart';
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
  final searchQuery = ''.obs;

  List<Product> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

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

  /// Returns true on success, so the caller (e.g. the add/edit sheet) knows
  /// whether it's safe to close — previously these threw uncaught, which
  /// silently left the sheet open with no error shown.
  Future<bool> createProduct(Product product) async {
    try {
      final created = await _repository.createProduct(product);
      products.add(created);
      return true;
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось создать товар.');
      return false;
    }
  }

  Future<void> toggleActive(Product product) async {
    try {
      final updated = await _repository.updateProduct(
        product.id,
        {'is_active': !product.isActive},
      );
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) products[index] = updated;
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось изменить товар.');
    }
  }

  Future<bool> editProduct(Product product, Map<String, dynamic> changes) async {
    try {
      final updated = await _repository.updateProduct(product.id, changes);
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) products[index] = updated;
      return true;
    } catch (e) {
      showErrorSnackbar(e, fallback: 'Не удалось сохранить товар.');
      return false;
    }
  }
}
