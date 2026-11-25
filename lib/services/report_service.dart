import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/formatters.dart';
import '../models/order_model.dart';

class ReportService {
  final SupabaseClient _client;

  ReportService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Fetches daily or date-range orders grouped by Asia/Jakarta (WIB) operational date.
  Future<List<OrderModel>> fetchOrdersReport({
    required DateTime startDate,
    required DateTime endDate,
    String? cashierId,
    OrderStatus? status,
    String? paymentMethod,
  }) async {
    final result = await _client.rpc(
      'get_orders_report',
      params: {
        'p_start_date': AppFormatters.isoDate(startDate),
        'p_end_date': AppFormatters.isoDate(endDate),
        'p_cashier_id': cashierId,
        'p_status': status?.dbValue,
        'p_payment_method': paymentMethod,
      },
    );

    if (result is! List<dynamic>) return [];
    return result
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  /// Cashier daily history (strictly today in WIB)
  Future<List<OrderModel>> fetchCashierTodayHistory() async {
    final today = AppFormatters.todayWib();
    return fetchOrdersReport(startDate: today, endDate: today);
  }
}
