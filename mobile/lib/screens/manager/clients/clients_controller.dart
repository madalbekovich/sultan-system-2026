import 'package:get/get.dart';

import '../../../data/clients_repository.dart';
import '../../../models/client.dart';

class ClientsController extends GetxController {
  ClientsController(this._repository);

  final ClientsRepository _repository;

  final clients = <Client>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    try {
      clients.assignAll(await _repository.fetchClients());
      errorMessage.value = null;
    } catch (_) {
      errorMessage.value = 'Could not load clients.';
    } finally {
      isLoading.value = false;
    }
  }
}
