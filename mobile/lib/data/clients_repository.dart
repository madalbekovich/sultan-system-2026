import '../core/api_client.dart';
import '../models/client.dart';
import '../models/price_sheet_row.dart';

class ClientsRepository {
  ClientsRepository(this._api);

  final ApiClient _api;

  Future<List<Client>> fetchClients({bool includeArchived = false}) async {
    final response = await _api.get<List<dynamic>>(
      '/clients/',
      query: {'include_archived': includeArchived},
    );
    return response.data!.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Client> createClient({
    required String name,
    String? phone,
    String? address,
    int? copyPricesFromClientId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/clients/',
      data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (copyPricesFromClientId != null) 'copy_prices_from_client_id': copyPricesFromClientId,
      },
    );
    return Client.fromJson(response.data!);
  }

  Future<Client> updateClient(
    int clientId, {
    String? name,
    String? phone,
    String? address,
    bool? isArchived,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/clients/$clientId',
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (isArchived != null) 'is_archived': isArchived,
      },
    );
    return Client.fromJson(response.data!);
  }

  Future<Client> unbindClient(int clientId) async {
    final response = await _api.patch<Map<String, dynamic>>('/clients/$clientId/unbind');
    return Client.fromJson(response.data!);
  }

  Future<List<PriceSheetRow>> fetchPriceSheet(int clientId) async {
    final response = await _api.get<List<dynamic>>('/clients/$clientId/price-sheet');
    return response.data!.map((e) => PriceSheetRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PriceImportResult> importPriceSheet(int clientId, List<PriceImportRow> rows) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/clients/$clientId/price-sheet/import',
      data: rows.map((r) => r.toJson()).toList(),
    );
    return PriceImportResult.fromJson(response.data!);
  }

  Future<void> copyPrices({required int targetClientId, required int sourceClientId}) async {
    await _api.post<Map<String, dynamic>>(
      '/clients/$targetClientId/copy-prices',
      data: {'source_client_id': sourceClientId},
    );
  }
}
