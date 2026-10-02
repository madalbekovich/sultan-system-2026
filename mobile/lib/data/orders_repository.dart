import 'dart:convert';

import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/dashboard_analytics.dart';
import '../models/order.dart';
import '../models/orders_summary.dart';

class OrdersRepository {
  OrdersRepository(this._api, this._storage);

  final ApiClient _api;
  final LocalStorage _storage;

  String _summaryCacheKey(String date) => 'summary_$date';
  String _ordersCacheKey(String date) => 'orders_$date';

  OrdersSummary? cachedSummary(String date) {
    final raw = _storage.getCache(_summaryCacheKey(date));
    if (raw == null) return null;
    return OrdersSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  List<Order> cachedOrders(String date) {
    final raw = _storage.getCache(_ordersCacheKey(date));
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrdersSummary> fetchSummary(String date) async {
    final response =
        await _api.get<Map<String, dynamic>>('/orders/summary', query: {'delivery_date': date});
    final summary = OrdersSummary.fromJson(response.data!);
    await _storage.setCache(_summaryCacheKey(date), jsonEncode(response.data));
    return summary;
  }

  Future<List<Order>> fetchOrders({
    String? deliveryDate,
    String? status,
    int? clientId,
  }) async {
    final query = <String, dynamic>{};
    if (deliveryDate != null) query['delivery_date'] = deliveryDate;
    if (status != null) query['status'] = status;
    if (clientId != null) query['client_id'] = clientId;

    final response = await _api.get<List<dynamic>>('/orders/', query: query);
    final orders =
        response.data!.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    if (deliveryDate != null && clientId == null) {
      await _storage.setCache(_ordersCacheKey(deliveryDate), jsonEncode(response.data));
    }
    return orders;
  }

  Future<DashboardAnalytics> fetchDashboardAnalytics({int days = 7}) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/orders/analytics/dashboard',
      query: {'days': days},
    );
    return DashboardAnalytics.fromJson(response.data!);
  }

  Future<List<int>> fetchWaybillPdf(int orderId) {
    return _api.getBytes('/orders/$orderId/waybill-pdf');
  }

  Future<Order> fetchOrder(int id) async {
    final response = await _api.get<Map<String, dynamic>>('/orders/$id');
    return Order.fromJson(response.data!);
  }

  Future<Order> updateItemWeight(int itemId, double actualQty) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/orders/items/$itemId/weight',
      data: {'actual_qty': actualQty},
    );
    return Order.fromJson(response.data!);
  }

  Future<Order> updateOrderStatus(int orderId, OrderStatus status) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/orders/$orderId/status',
      data: {'status': _statusToJson(status)},
    );
    return Order.fromJson(response.data!);
  }

  String _statusToJson(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.inAssembly:
        return 'IN_ASSEMBLY';
      case OrderStatus.ready:
        return 'READY';
      case OrderStatus.dispatched:
        return 'DISPATCHED';
    }
  }
}
