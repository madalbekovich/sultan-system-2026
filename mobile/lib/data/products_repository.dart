import 'dart:convert';

import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/category.dart';
import '../models/price_sheet_row.dart';
import '../models/product.dart';

class ProductsRepository {
  ProductsRepository(this._api, this._storage);

  final ApiClient _api;
  final LocalStorage _storage;

  static const _productsCacheKey = 'products';
  static const _categoriesCacheKey = 'categories';

  List<Product> cachedProducts() {
    final raw = _storage.getCache(_productsCacheKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Category> cachedCategories() {
    final raw = _storage.getCache(_categoriesCacheKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> fetchCategories() async {
    final response = await _api.get<List<dynamic>>('/categories/');
    final categories =
        response.data!.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    await _storage.setCache(_categoriesCacheKey, jsonEncode(response.data));
    return categories;
  }

  Future<List<Product>> fetchProducts({bool activeOnly = true}) async {
    final response = await _api.get<List<dynamic>>(
      '/products/',
      query: {'active_only': activeOnly},
    );
    final products =
        response.data!.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    await _storage.setCache(_productsCacheKey, jsonEncode(response.data));
    return products;
  }

  Future<Product> createProduct(Product product) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/products/',
      data: product.toCreateJson(),
    );
    return Product.fromJson(response.data!);
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> changes) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/products/$id',
      data: changes,
    );
    return Product.fromJson(response.data!);
  }

  Future<List<PriceCoverage>> fetchPriceCoverage() async {
    final response = await _api.get<List<dynamic>>('/products/price-coverage');
    return response.data!.map((e) => PriceCoverage.fromJson(e as Map<String, dynamic>)).toList();
  }
}
