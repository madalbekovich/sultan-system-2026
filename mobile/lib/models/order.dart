enum OrderStatus { pending, inAssembly, ready, dispatched }

OrderStatus orderStatusFromJson(String value) {
  switch (value) {
    case 'IN_ASSEMBLY':
      return OrderStatus.inAssembly;
    case 'READY':
      return OrderStatus.ready;
    case 'DISPATCHED':
      return OrderStatus.dispatched;
    default:
      return OrderStatus.pending;
  }
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.inAssembly:
        return 'В сборке';
      case OrderStatus.ready:
        return 'Готов';
      case OrderStatus.dispatched:
        return 'Отгружен';
    }
  }
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.plannedQty,
    this.actualQty,
    this.finalPrice,
    this.productName,
  });

  final int id;
  final int productId;
  final double plannedQty;
  final double? actualQty;
  final double? finalPrice;
  final String? productName;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int,
        productId: json['product_id'] as int,
        plannedQty: double.parse(json['planned_qty'].toString()),
        actualQty: json['actual_qty'] != null
            ? double.parse(json['actual_qty'].toString())
            : null,
        finalPrice: json['final_price'] != null
            ? double.parse(json['final_price'].toString())
            : null,
        productName: json['product_name'] as String?,
      );
}

/// Day-level totals across a list of orders — the one place that sums
/// amount/weight so screens never each write their own fold().
extension OrderListTotals on List<Order> {
  double get totalAmountSum => fold(0.0, (sum, o) => sum + o.totalAmount);
  double get totalWeightGramsSum =>
      fold(0.0, (sum, o) => sum + o.totalWeightGrams);
}

class Order {
  Order({
    required this.id,
    required this.clientId,
    required this.deliveryDate,
    required this.status,
    required this.totalAmount,
    required this.totalWeightGrams,
    required this.items,
    this.clientName,
    this.clientCode,
  });

  final int id;
  final int clientId;
  final DateTime deliveryDate;
  final OrderStatus status;
  final double totalAmount;
  final String? clientCode;

  /// Computed once, backend-side (see services/orders.py::_item_weight_grams)
  /// so the app never re-derives this from items — read it, don't recompute.
  final double totalWeightGrams;
  final List<OrderItem> items;
  final String? clientName;

  /// Sum of quantity across all items — actual qty once the shop has
  /// weighed/counted it, falling back to the planned qty before that.
  double get totalQty =>
      items.fold(0.0, (sum, item) => sum + (item.actualQty ?? item.plannedQty));

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        clientId: json['client_id'] as int,
        deliveryDate: DateTime.parse(json['delivery_date'] as String),
        status: orderStatusFromJson(json['status'] as String),
        totalAmount: double.parse(json['total_amount'].toString()),
        totalWeightGrams: double.parse((json['total_weight_grams'] ?? 0).toString()),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        clientName: json['client_name'] as String?,
        clientCode: json['client_code'] as String?,
      );
}
