import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_client.dart';

/// A failed action with no visible result reads as "the app doesn't work".
/// Call this from any catch block that previously swallowed the error
/// silently — it shows the server's actual message when available.
void showErrorSnackbar(Object error, {String fallback = 'Что-то пошло не так.'}) {
  final message = error is ApiException ? error.message : fallback;
  Get.snackbar(
    'Ошибка',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red.shade700,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
  );
}
