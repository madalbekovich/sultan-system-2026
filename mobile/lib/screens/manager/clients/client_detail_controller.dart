import 'package:get/get.dart';

import '../../../data/clients_repository.dart';
import '../../../data/orders_repository.dart';
import '../../../data/products_repository.dart';
import '../../../models/category.dart';
import '../../../models/client.dart';
import '../../../models/order.dart';
import '../../../models/price_sheet_row.dart';
import '../../../models/product.dart';

class ClientDetailController extends GetxController {
  ClientDetailController(
    this._ordersRepository,
    this._clientsRepository,
    this._productsRepository,
    Client client,
  ) : client = Rx<Client>(client);

  final OrdersRepository _ordersRepository;
  final ClientsRepository _clientsRepository;
  final ProductsRepository _productsRepository;

  final Rx<Client> client;
  final orders = <Order>[].obs;
  final priceSheet = <PriceSheetRow>[].obs;
  final categories = <Category>[].obs;
  final isLoading = true.obs;
  final isLoadingPrices = true.obs;
  final errorMessage = RxnString();
  final isUnbinding = false.obs;

  double get totalSpent =>
      orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

  @override
  void onInit() {
    super.onInit();
    load();
    loadPriceSheet();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      categories.assignAll(await _productsRepository.fetchCategories());
    } catch (_) {
      // Categories failing to load just means the "add product" form can't
      // offer a category picker yet — retried next time the screen opens.
    }
  }

  /// Adds a product to the one shared catalog (it then shows up for every
  /// warehouse, priced at base until someone sets their own price) —
  /// there's no per-warehouse product list, only per-warehouse prices.
  Future<bool> createCatalogProduct(Product product) async {
    try {
      await _productsRepository.createProduct(product);
      await loadPriceSheet();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editCatalogProduct(Product existing, Map<String, dynamic> changes) async {
    try {
      await _productsRepository.updateProduct(existing.id, changes);
      await loadPriceSheet();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Soft-deletes a product (same `is_active` toggle used everywhere else
  /// in the catalog) — it disappears from ordering but its history stays.
  Future<bool> deactivateProduct(int productId) async {
    try {
      await _productsRepository.updateProduct(productId, {'is_active': false});
      await loadPriceSheet();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      orders.assignAll(await _ordersRepository.fetchOrders(clientId: client.value.id));
      errorMessage.value = null;
    } catch (_) {
      errorMessage.value = 'Не удалось загрузить заказы клиента.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPriceSheet() async {
    isLoadingPrices.value = true;
    try {
      priceSheet.assignAll(await _clientsRepository.fetchPriceSheet(client.value.id));
    } catch (_) {
      // Price sheet failing to load shouldn't block the rest of the screen —
      // the section just stays empty and the manager can retry by reopening.
    } finally {
      isLoadingPrices.value = false;
    }
  }

  /// Manager-only — clears the Telegram binding so the warehouse's code
  /// can be entered again from a different account.
  Future<bool> unbind() async {
    isUnbinding.value = true;
    try {
      client.value = await _clientsRepository.unbindClient(client.value.id);
      return true;
    } catch (_) {
      return false;
    } finally {
      isUnbinding.value = false;
    }
  }

  /// Manager-only — edits the warehouse's own business details (name,
  /// phone, address). Never touches code/binding/prices.
  Future<bool> updateInfo({required String name, String? phone, String? address}) async {
    try {
      client.value = await _clientsRepository.updateClient(
        client.value.id,
        name: name,
        phone: phone,
        address: address,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setArchived(bool archived) async {
    try {
      client.value = await _clientsRepository.updateClient(client.value.id, isArchived: archived);
      return true;
    } catch (_) {
      return false;
    }
  }
}
