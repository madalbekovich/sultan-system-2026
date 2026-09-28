import '../core/api_client.dart';
import '../core/storage.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final LocalStorage _storage;

  bool get isLoggedIn => _storage.token != null;

  Future<void> login(String username, String password) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/',
      data: {'username': username, 'password': password},
    );
    final token = response.data!['access_token'] as String;
    await _storage.setToken(token);
  }

  Future<void> logout() => _storage.clearToken();
}
