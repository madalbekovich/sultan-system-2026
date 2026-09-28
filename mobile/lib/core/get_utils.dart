import 'package:get/get.dart';

/// `Get.put` always overwrites (and leaks — the old instance's onClose is
/// never called) whatever was registered under the same tag. Screens that
/// call `Get.put` directly inside `build()` re-register — and for
/// controllers holding a Timer/stream, leak — every time that route is
/// pushed again (e.g. navigating back to a tab and returning to it).
/// This reuses the existing controller instead of replacing it.
T putOnce<T extends GetxController>(T Function() create, {required String tag}) {
  if (Get.isRegistered<T>(tag: tag)) {
    return Get.find<T>(tag: tag);
  }
  return Get.put<T>(create(), tag: tag);
}
