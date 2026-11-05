import 'package:get/get.dart';

import '../../../data/clients_repository.dart';
import '../../../models/client.dart';

class ClientsController extends GetxController {
  ClientsController(this._repository);

  final ClientsRepository _repository;

  final clients = <Client>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;
  final showArchived = false.obs;

  List<Client> get filteredClients {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return clients;
    return clients.where((c) =>
        c.name.toLowerCase().contains(query) ||
        c.clientCode.toLowerCase().contains(query) ||
        (c.phone ?? '').contains(query)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    reload();
    ever(showArchived, (_) => reload());
  }

  Future<void> reload() async {
    isLoading.value = true;
    try {
      clients.assignAll(await _repository.fetchClients(includeArchived: showArchived.value));
      errorMessage.value = null;
    } catch (_) {
      errorMessage.value = 'Не удалось загрузить клиентов.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createClient({
    required String name,
    String? phone,
    String? address,
    int? copyPricesFromClientId,
  }) async {
    try {
      final created = await _repository.createClient(
        name: name,
        phone: phone,
        address: address,
        copyPricesFromClientId: copyPricesFromClientId,
      );
      clients.add(created);
      return true;
    } catch (_) {
      return false;
    }
  }
}
