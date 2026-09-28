/// API base URL. Override at build/run time with:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Poll interval for the workshop's "live" production summary screen.
  static const Duration summaryPollInterval = Duration(seconds: 10);
}
