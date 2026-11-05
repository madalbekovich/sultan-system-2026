class ProductSummaryEntry {
  ProductSummaryEntry({
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.totalPlannedQty,
    required this.totalWeightGrams,
    required this.clientCount,
  });

  final int productId;
  final String productName;
  final String unitType;
  final double totalPlannedQty;
  final double totalWeightGrams;
  final int clientCount;

  factory ProductSummaryEntry.fromJson(Map<String, dynamic> json) =>
      ProductSummaryEntry(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        unitType: json['unit_type'] as String,
        totalPlannedQty: double.parse(json['total_planned_qty'].toString()),
        totalWeightGrams:
            double.parse((json['total_weight_grams'] ?? 0).toString()),
        clientCount: json['client_count'] as int,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'unit_type': unitType,
        'total_planned_qty': totalPlannedQty,
        'total_weight_grams': totalWeightGrams,
        'client_count': clientCount,
      };
}

class OrdersSummary {
  OrdersSummary({
    required this.deliveryDate,
    required this.orderCount,
    required this.products,
  });

  final String deliveryDate;
  final int orderCount;
  final List<ProductSummaryEntry> products;

  /// Total weight across every product line — one place, read by whichever
  /// screen needs the day's weight total instead of re-summing itself.
  double get totalWeightGrams =>
      products.fold(0.0, (sum, p) => sum + p.totalWeightGrams);

  factory OrdersSummary.fromJson(Map<String, dynamic> json) => OrdersSummary(
        deliveryDate: json['delivery_date'] as String,
        orderCount: json['order_count'] as int? ?? 0,
        products: (json['products'] as List<dynamic>)
            .map((e) => ProductSummaryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'delivery_date': deliveryDate,
        'order_count': orderCount,
        'products': products.map((p) => p.toJson()).toList(),
      };
}
