import '../core/api_client.dart';
import '../models/client.dart';

class ClientsRepository {
  ClientsRepository(this._api);

  final ApiClient _api;

  Future<List<Client>> fetchClients() async {
    final response = await _api.get<List<dynamic>>('/clients/');
    return response.data!.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
  }
}
