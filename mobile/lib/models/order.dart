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

class Order {
  Order({
    required this.id,
    required this.clientId,
    required this.deliveryDate,
    required this.status,
    required this.totalAmount,
    required this.items,
    this.clientName,
  });

  final int id;
  final int clientId;
  final DateTime deliveryDate;
  final OrderStatus status;
  final double totalAmount;
  final List<OrderItem> items;
  final String? clientName;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        clientId: json['client_id'] as int,
        deliveryDate: DateTime.parse(json['delivery_date'] as String),
        status: orderStatusFromJson(json['status'] as String),
        totalAmount: double.parse(json['total_amount'].toString()),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        clientName: json['client_name'] as String?,
      );
}
