class PriceSheetRow {
  PriceSheetRow({
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.basePrice,
    required this.ownPrice,
    required this.hasOwnPrice,
  });

  final int productId;
  final String productName;
  final String unitType;
  final double basePrice;
  final double? ownPrice;
  final bool hasOwnPrice;

  /// What the warehouse actually pays — its own price if set, base otherwise.
  double get effectivePrice => ownPrice ?? basePrice;

  factory PriceSheetRow.fromJson(Map<String, dynamic> json) => PriceSheetRow(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        unitType: json['unit_type'] as String,
        basePrice: double.parse(json['base_price'].toString()),
        ownPrice: json['own_price'] != null ? double.parse(json['own_price'].toString()) : null,
        hasOwnPrice: json['has_own_price'] as bool,
      );
}

class PriceImportRow {
  PriceImportRow({required this.row, required this.productId, required this.price});

  final int row;
  final int? productId;
  final String? price;

  Map<String, dynamic> toJson() => {'row': row, 'product_id': productId, 'price': price};
}

class PriceImportError {
  PriceImportError({required this.row, required this.productId, required this.message});

  final int row;
  final int? productId;
  final String message;

  factory PriceImportError.fromJson(Map<String, dynamic> json) => PriceImportError(
        row: json['row'] as int,
        productId: json['product_id'] as int?,
        message: json['message'] as String,
      );
}

class PriceImportResult {
  PriceImportResult({required this.ok, required this.updated, required this.cleared, required this.errors});

  final bool ok;
  final int updated;
  final int cleared;
  final List<PriceImportError> errors;

  factory PriceImportResult.fromJson(Map<String, dynamic> json) => PriceImportResult(
        ok: json['ok'] as bool,
        updated: json['updated'] as int,
        cleared: json['cleared'] as int,
        errors: (json['errors'] as List<dynamic>)
            .map((e) => PriceImportError.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PriceCoverage {
  PriceCoverage({
    required this.productId,
    required this.productName,
    required this.clientsTotal,
    required this.clientsWithOwnPrice,
    required this.clientsMissing,
  });

  final int productId;
  final String productName;
  final int clientsTotal;
  final int clientsWithOwnPrice;
  final int clientsMissing;

  factory PriceCoverage.fromJson(Map<String, dynamic> json) => PriceCoverage(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        clientsTotal: json['clients_total'] as int,
        clientsWithOwnPrice: json['clients_with_own_price'] as int,
        clientsMissing: json['clients_missing'] as int,
      );
}
