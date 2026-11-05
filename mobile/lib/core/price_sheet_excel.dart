import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/client.dart';
import '../models/price_sheet_row.dart';

/// One parsed Excel row, before it's sent to the backend for validation —
/// kept separate from [PriceImportRow] so the preview screen can show the
/// product name/base price alongside whatever the manager typed, even for
/// rows that turn out to be invalid.
class ParsedPriceRow {
  ParsedPriceRow({
    required this.row,
    required this.productId,
    required this.productName,
    required this.priceText,
  });

  final int row;
  final int? productId;
  final String productName;
  final String priceText;

  PriceImportRow toImportRow() => PriceImportRow(row: row, productId: productId, price: priceText);
}

/// Export/import for a single warehouse's price sheet — the template is
/// always pre-filled with that warehouse's current effective prices (own
/// price if set, otherwise base), never blank, so the manager edits a
/// real sheet instead of filling one in from scratch.
class PriceSheetExcelService {
  static const _headers = ['ID', 'Товар', 'Ед.', 'Базовая цена', 'Цена склада'];

  static Future<void> export({required Client client, required List<PriceSheetRow> rows}) async {
    final workbook = xl.Excel.createExcel();
    final sheet = workbook['Цены'];
    for (var c = 0; c < _headers.length; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = xl.TextCellValue(_headers[c]);
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle =
          xl.CellStyle(bold: true);
    }

    var row = 1;
    for (final r in rows) {
      _setCell(sheet, 0, row, xl.IntCellValue(r.productId));
      _setCell(sheet, 1, row, xl.TextCellValue(r.productName));
      _setCell(sheet, 2, row, xl.TextCellValue(r.unitType == 'PCS' ? 'шт' : 'кг'));
      _setCell(sheet, 3, row, xl.DoubleCellValue(r.basePrice));
      _setCell(sheet, 4, row, xl.DoubleCellValue(r.effectivePrice));
      row++;
    }

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 36);
    sheet.setColumnWidth(2, 8);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 16);

    if (workbook.tables.containsKey('Sheet1')) workbook.delete('Sheet1');

    final bytes = workbook.encode();
    if (bytes == null) throw Exception('Не удалось сформировать файл.');

    final fileName = 'Prices_${client.clientCode}.xlsx';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [fileName]),
    );
  }

  static void _setCell(xl.Sheet sheet, int col, int row, xl.CellValue value) {
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = value;
  }

  /// Opens the system file picker and parses the chosen .xlsx — returns
  /// null if the user cancelled. Throws on a file that isn't a readable
  /// spreadsheet in the expected shape; callers show that as a single
  /// "файл повреждён" message rather than per-row errors (those only make
  /// sense once the shape itself is valid).
  static Future<List<ParsedPriceRow>?> pickAndParse() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (files.isEmpty || files.single.path == null) return null;

    final bytes = await File(files.single.path!).readAsBytes();
    final workbook = xl.Excel.decodeBytes(bytes);
    final sheet = workbook.tables[workbook.tables.keys.first];
    if (sheet == null) throw Exception('Пустой файл.');

    final rows = <ParsedPriceRow>[];
    for (var i = 1; i < sheet.maxRows; i++) {
      final cells = sheet.row(i);
      if (cells.isEmpty || cells.every((c) => c?.value == null)) continue;
      final productId = _asInt(cells.isNotEmpty ? cells[0]?.value : null);
      final productName = (cells.length > 1 ? cells[1]?.value : null)?.toString() ?? '';
      final priceText = (cells.length > 4 ? cells[4]?.value : null)?.toString() ?? '';
      rows.add(ParsedPriceRow(row: i + 1, productId: productId, productName: productName, priceText: priceText));
    }
    return rows;
  }

  static int? _asInt(xl.CellValue? value) {
    if (value == null) return null;
    final text = value.toString();
    return int.tryParse(text);
  }
}
