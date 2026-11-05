import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Thin wrapper around connectivity_plus — the single place that decides
/// "does this device currently have a network interface up". Radio status
/// isn't the same as "the API is reachable" (captive portals, VPNs, a down
/// backend all slip through), so this is only one half of the offline vs.
/// server-error classification in [ApiClient]; it's what lets a screen
/// auto-retry the instant the device actually reconnects.
class ConnectivityService extends GetxService {
  final isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    Connectivity().checkConnectivity().then(_apply);
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    isOnline.value = results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
