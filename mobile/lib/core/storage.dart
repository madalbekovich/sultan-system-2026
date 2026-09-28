import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for the auth token and the
/// offline-first JSON caches (last-known summary / catalog / orders),
/// so screens can render instantly while a fresh fetch is in flight.
class LocalStorage {
  LocalStorage._(this._prefs);

  final SharedPreferences _prefs;

  static LocalStorage? _instance;

  static Future<LocalStorage> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = LocalStorage._(prefs);
    return _instance!;
  }

  static const _tokenKey = 'auth_token';

  String? get token => _prefs.getString(_tokenKey);

  Future<void> setToken(String token) => _prefs.setString(_tokenKey, token);

  Future<void> clearToken() => _prefs.remove(_tokenKey);

  Future<void> setCache(String key, String jsonBody) =>
      _prefs.setString('cache_$key', jsonBody);

  String? getCache(String key) => _prefs.getString('cache_$key');
}
