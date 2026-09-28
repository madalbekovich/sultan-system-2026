class ProductSummaryEntry {
  ProductSummaryEntry({
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.totalPlannedQty,
    required this.clientCount,
  });

  final int productId;
  final String productName;
  final String unitType;
  final double totalPlannedQty;
  final int clientCount;

  factory ProductSummaryEntry.fromJson(Map<String, dynamic> json) =>
      ProductSummaryEntry(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        unitType: json['unit_type'] as String,
        totalPlannedQty: double.parse(json['total_planned_qty'].toString()),
        clientCount: json['client_count'] as int,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'unit_type': unitType,
        'total_planned_qty': totalPlannedQty,
        'client_count': clientCount,
      };
}

class OrdersSummary {
  OrdersSummary({required this.deliveryDate, required this.products});

  final String deliveryDate;
  final List<ProductSummaryEntry> products;

  factory OrdersSummary.fromJson(Map<String, dynamic> json) => OrdersSummary(
        deliveryDate: json['delivery_date'] as String,
        products: (json['products'] as List<dynamic>)
            .map((e) => ProductSummaryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'delivery_date': deliveryDate,
        'products': products.map((p) => p.toJson()).toList(),
      };
}
