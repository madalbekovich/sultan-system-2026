import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/ru_text.dart';
import '../data/orders_repository.dart';
import '../models/order.dart';
import '../models/orders_summary.dart';

/// Builds and shares the day's "Sultan_ceh_<date>.xlsx" report — a
/// "Сводка" sheet (per-product totals, same numbers as the on-screen
/// summary) and a "Заказы" sheet (one row per order item across the
/// day). Pulled fresh from the API so the export always matches what's
/// actually on the server, not just whatever happens to be cached in the
/// screen that triggered it.
class ExcelExportService {
  static xl.CellStyle get _headerStyle => xl.CellStyle(bold: true);
  static xl.CellStyle get _totalsStyle => xl.CellStyle(
        bold: true,
        backgroundColorHex: xl.ExcelColor.fromHexString('FFF3DAA3'),
      );
  static xl.CellStyle get _numberStyle =>
      xl.CellStyle(numberFormat: xl.NumFormat.standard_4);

  /// Fetches the day's orders + summary, builds the workbook, writes it to
  /// a temp file and opens the system share sheet. Throws on network
  /// failure — callers show that however fits their screen.
  static Future<void> exportDay({
    required OrdersRepository repository,
    required DateTime date,
    required String dateKey,
  }) async {
    final results = await Future.wait([
      repository.fetchOrders(deliveryDate: dateKey),
      repository.fetchSummary(dateKey),
    ]);
    final orders = results[0] as List<Order>;
    final summary = results[1] as OrdersSummary;

    final workbook = xl.Excel.createExcel();
    _buildSummarySheet(workbook, summary);
    _buildOrdersSheet(workbook, orders);
    // The library always creates a default "Sheet1" — drop it once our
    // two real sheets exist so recipients don't see a stray empty tab.
    if (workbook.tables.containsKey('Sheet1')) {
      workbook.delete('Sheet1');
    }

    final bytes = workbook.encode();
    if (bytes == null) throw Exception('Не удалось сформировать файл.');

    final fileName = 'Sultan_ceh_$dateKey.xlsx';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [fileName]),
    );
  }

  static void _setCell(
    xl.Sheet sheet,
    int col,
    int row,
    xl.CellValue? value, {
    xl.CellStyle? style,
  }) {
    final cell = sheet.cell(
      xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  static void _buildSummarySheet(xl.Excel workbook, OrdersSummary summary) {
    final sheet = workbook['Сводка'];
    const headers = ['Товар', 'Количество', 'Вес, кг', 'Клиентов'];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, c, 0, xl.TextCellValue(headers[c]), style: _headerStyle);
    }

    var row = 1;
    for (final entry in summary.products) {
      final unitLabel = unitLabelRu(entry.unitType);
      _setCell(sheet, 0, row, xl.TextCellValue(entry.productName));
      _setCell(sheet, 1, row,
          xl.TextCellValue('${_trimNumber(entry.totalPlannedQty)} $unitLabel'));
      _setCell(sheet, 2, row, xl.DoubleCellValue(entry.totalWeightGrams / 1000),
          style: _numberStyle);
      _setCell(sheet, 3, row, xl.IntCellValue(entry.clientCount));
      row++;
    }

    _setCell(sheet, 0, row, xl.TextCellValue('Итого (${summary.products.length} товаров)'),
        style: _totalsStyle);
    _setCell(sheet, 1, row, xl.TextCellValue(''), style: _totalsStyle);
    _setCell(sheet, 2, row, xl.DoubleCellValue(summary.totalWeightGrams / 1000),
        style: _totalsStyle..numberFormat = xl.NumFormat.standard_4);
    _setCell(sheet, 3, row, xl.TextCellValue(''), style: _totalsStyle);

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 12);
  }

  static void _buildOrdersSheet(xl.Excel workbook, List<Order> orders) {
    final sheet = workbook['Заказы'];
    const headers = ['№', 'Клиент', 'Код', 'Товар', 'Количество', 'Цена', 'Сумма', 'Статус'];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, c, 0, xl.TextCellValue(headers[c]), style: _headerStyle);
    }

    double totalAmount = 0;
    var row = 1;
    for (final order in orders) {
      final clientName = order.clientName ?? 'Клиент №${order.clientId}';
      for (final item in order.items) {
        final qty = item.actualQty ?? item.plannedQty;
        final lineTotal = item.finalPrice ?? 0;
        final unitPrice = item.plannedQty == 0 ? 0.0 : lineTotal / item.plannedQty;
        totalAmount += lineTotal;

        _setCell(sheet, 0, row, xl.IntCellValue(order.id));
        _setCell(sheet, 1, row, xl.TextCellValue(clientName));
        _setCell(sheet, 2, row, xl.TextCellValue(order.clientCode ?? '—'));
        _setCell(sheet, 3, row,
            xl.TextCellValue(item.productName ?? 'Товар №${item.productId}'));
        _setCell(sheet, 4, row, xl.DoubleCellValue(qty), style: _numberStyle);
        _setCell(sheet, 5, row, xl.DoubleCellValue(unitPrice), style: _numberStyle);
        _setCell(sheet, 6, row, xl.DoubleCellValue(lineTotal), style: _numberStyle);
        _setCell(sheet, 7, row, xl.TextCellValue(order.status.label));
        row++;
      }
    }

    _setCell(sheet, 0, row, xl.TextCellValue('Итого'), style: _totalsStyle);
    for (final c in [1, 2, 3, 4, 5]) {
      _setCell(sheet, c, row, xl.TextCellValue(''), style: _totalsStyle);
    }
    _setCell(sheet, 6, row, xl.DoubleCellValue(totalAmount),
        style: _totalsStyle..numberFormat = xl.NumFormat.standard_4);
    _setCell(sheet, 7, row, xl.TextCellValue(''), style: _totalsStyle);

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 32);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 10);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 14);
  }

  static String _trimNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2).replaceFirst('.', ',');
  }
}
