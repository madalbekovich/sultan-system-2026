import 'order.dart';
import 'orders_summary.dart';

class DailySales {
  DailySales({required this.deliveryDate, required this.totalAmount, required this.orderCount});

  final DateTime deliveryDate;
  final double totalAmount;
  final int orderCount;

  factory DailySales.fromJson(Map<String, dynamic> json) => DailySales(
        deliveryDate: DateTime.parse(json['delivery_date'] as String),
        totalAmount: double.parse(json['total_amount'].toString()),
        orderCount: json['order_count'] as int,
      );
}

class DashboardAnalytics {
  DashboardAnalytics({
    required this.dailySales,
    required this.topProducts,
    required this.recentOrders,
  });

  final List<DailySales> dailySales;
  final List<ProductSummaryEntry> topProducts;
  final List<Order> recentOrders;

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) => DashboardAnalytics(
        dailySales: (json['daily_sales'] as List<dynamic>)
            .map((e) => DailySales.fromJson(e as Map<String, dynamic>))
            .toList(),
        topProducts: (json['top_products'] as List<dynamic>)
            .map((e) => ProductSummaryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentOrders: (json['recent_orders'] as List<dynamic>)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
