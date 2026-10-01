import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../data/orders_repository.dart';
import 'api_client.dart';

/// Shared print/share-PDF actions for an order's waybill, used by both the
/// manual "type an order number" screen and the per-order button in the
/// manager's order list. Returns an error message on failure, null on
/// success, so callers can show it however fits their UI.
class WaybillActions {
  static Future<String?> print(int orderId) => _run(orderId, (bytes) {
        return Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes));
      });

  static Future<String?> share(int orderId) => _run(orderId, (bytes) {
        return Printing.sharePdf(
          bytes: Uint8List.fromList(bytes),
          filename: 'waybill-$orderId.pdf',
        );
      });

  static Future<String?> _run(
    int orderId,
    Future<void> Function(List<int> bytes) action,
  ) async {
    try {
      final bytes = await Get.find<OrdersRepository>().fetchWaybillPdf(orderId);
      await action(bytes);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Не удалось получить накладную.';
    }
  }
}
