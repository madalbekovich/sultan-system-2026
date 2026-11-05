import 'dart:async';

import 'package:get/get.dart';

import 'api_client.dart';
import 'connectivity_service.dart';

enum DataStatus { ok, offline, serverError }

/// Shared "is the data on screen fresh, and if not, why" tracking — every
/// list/dashboard controller used to duplicate a bare try/catch that lumped
/// connectivity loss and server errors into the same "Нет сети" banner.
/// This is the one place that tells them apart and drives the retry button
/// + auto-retry-on-reconnect, so every screen behaves the same way.
mixin RefreshStatusMixin on GetxController {
  final dataStatus = DataStatus.ok.obs;
  final lastUpdated = Rxn<DateTime>();
  StreamSubscription<bool>? _connectivitySub;

  /// Call once from onInit, passing the controller's own reload function —
  /// when the device reconnects while this screen is showing stale data,
  /// it retries automatically instead of waiting for the user to notice.
  void watchConnectivity(Future<void> Function() reload) {
    if (!Get.isRegistered<ConnectivityService>()) return;
    _connectivitySub =
        Get.find<ConnectivityService>().isOnline.listen((online) {
      if (online && dataStatus.value != DataStatus.ok) reload();
    });
  }

  /// Wraps a refresh call: on success marks the data fresh and stamps
  /// [lastUpdated]; on failure classifies the cause via [ApiException.kind]
  /// without touching lastUpdated, so the banner can keep showing when it
  /// was last actually updated.
  Future<void> runGuarded(Future<void> Function() body) async {
    try {
      await body();
      dataStatus.value = DataStatus.ok;
      lastUpdated.value = DateTime.now();
    } catch (e) {
      dataStatus.value = (e is ApiException && e.kind == ApiFailureKind.network)
          ? DataStatus.offline
          : DataStatus.serverError;
    }
  }

  void disposeRefreshStatus() => _connectivitySub?.cancel();
}
