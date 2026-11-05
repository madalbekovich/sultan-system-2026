import 'package:get/get.dart';

import '../../../core/error_feedback.dart';
import '../../../core/refresh_status.dart';
import '../../../data/products_repository.dart';
import '../../../models/category.dart';
import '../../../models/price_sheet_row.dart';
import '../../../models/product.dart';

class CatalogController extends GetxController with RefreshStatusMixin {
  CatalogController(this._repository);

  final ProductsRepository _repository;

  final products = <Product>[].obs;
  final categories = <Category>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final priceCoverage = <int, PriceCoverage>{}.obs;
  final showOnlyMissingPrice = false.obs;

  List<Product> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    List<Product> result = products;
    if (query.isNotEmpty) {
      result = result.where((p) => p.name.toLowerCase().contains(query)).toList();
    }
    if (showOnlyMissingPrice.value) {
      result = result.where((p) => (priceCoverage[p.id]?.clientsMissing ?? 0) > 0).toList();
    }
    return result;
  }

  @override
  void onInit() {
    super.onInit();
    products.assignAll(_repository.cachedProducts());
    categories.assignAll(_repository.cachedCategories());
    isLoading.value = products.isEmpty;
    reload();
    watchConnectivity(reload);
  }

  @override
  void onClose() {
    disposeRefreshStatus();
    super.onClose();
  }

  Future<void> reload() async {
    await runGuarded(() async {
      final results = await Future.wait([
        _repository.fetchProducts(activeOnly: false),
        _repository.fetchCategories(),
        _repository.fetchPriceCoverage(),
      ]);
      products.assignAll(results[0] as List<Product>);
      categories.assignAll(results[1] as List<Category>);
      priceCoverage.assignAll({
        for (final c in results[2] as List<PriceCoverage>) c.productId: c,
      });
    });
    isLoading.value = false;
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
