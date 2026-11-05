import 'package:flutter/foundation.dart' show kReleaseMode;

/// API base URL. Override at build/run time with:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1
///
/// Release builds (flutter build ipa/apk, which always compile in release
/// mode) default to the production server over HTTPS instead of localhost,
/// so a TestFlight build talks to the real API without needing
/// --dart-define passed at archive time. Debug/profile runs still default
/// to localhost for local backend testing, same as before.
class AppConfig {
  static const String _prodApiBaseUrl = 'https://sultan.dosdev.space/api/v1';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? _prodApiBaseUrl : 'http://localhost:8000/api/v1',
  );

  /// Poll interval for the workshop's "live" production summary screen.
  static const Duration summaryPollInterval = Duration(seconds: 10);
}
