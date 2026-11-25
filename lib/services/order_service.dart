import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _client;

  OrderService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Creates an order via PostgreSQL RPC `create_order` so price snapshots and
  /// total_amount are authoritatively calculated on the server (anti-tampering).
  Future<OrderModel> createOrder({
    required List<CartItem> items,
    required PaymentMethod paymentMethod,
    int expiryMinutes = 20,
  }) async {
    if (items.isEmpty) {
      throw Exception('Keranjang pesanan masih kosong.');
    }

    final payload = items
        .map((c) => {'menu_id': c.menu.id, 'quantity': c.quantity})
        .toList();

    final result = await _client.rpc(
      'create_order',
      params: {
        'p_items': payload,
        'p_payment_method': paymentMethod.code,
        'p_expiry_minutes': expiryMinutes,
      },
    );

    if (result is! Map<String, dynamic>) {
      throw Exception('Respons pembuatan pesanan tidak valid.');
    }
    final orderId = result['id'] as String;
    return await fetchOrderById(orderId);
  }

  /// Fetches full order detail including items and payment payload
  Future<OrderModel> fetchOrderById(String orderId) async {
    final row = await _client
        .from('orders')
        .select('*, order_items(*), payments(*)')
        .eq('id', orderId)
        .single();

    return OrderModel.fromJson(row);
  }

  /// Fetches personal order history for the signed-in User (isolated via RLS)
  Future<List<OrderModel>> fetchUserOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('orders')
        .select('*, order_items(*), payments(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => OrderModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Cashier / Admin lookup by scanned QR token or manually typed order_code
  Future<OrderModel> lookupOrderByQrOrCode(String qrOrOrderCode) async {
    final cleaned = qrOrOrderCode.trim();
    if (cleaned.isEmpty) {
      throw Exception('Kode QR atau nomor pesanan tidak boleh kosong.');
    }

    final result = await _client.rpc(
      'get_order_by_qr_or_code',
      params: {'p_identifier': cleaned},
    );

    if (result is! Map<String, dynamic>) {
      throw Exception('Pesanan tidak ditemukan.');
    }
    return OrderModel.fromJson(result);
  }

  /// Cashier approves order -> invokes Edge Function `approve-and-charge-order`
  /// which verifies kasir role, locks row atomically, and generates Xendit Test Mode charge.
  Future<OrderModel> approveAndChargeOrder(String orderId) async {
    try {
      final resp = await _client.functions.invoke(
        'approve-and-charge-order',
        body: {'order_id': orderId},
      );

      final data = resp.data;
      if (resp.status >= 400) {
        final msg = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Gagal menyetujui pesanan (HTTP ${resp.status}).';
        throw Exception(msg);
      }

      return await fetchOrderById(orderId);
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }
      throw Exception(e.reasonPhrase ?? 'Gagal menghubungi layanan pembayaran.');
    }
  }

  /// Cashier rejects order with mandatory reason via PostgreSQL RPC `reject_order`
  Future<void> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw Exception('Alasan penolakan wajib diisi.');
    }

    await _client.rpc(
      'reject_order',
      params: {
        'p_order_id': orderId,
        'p_reason': cleanReason,
      },
    );
  }

  /// Dev / Test Mode utility: triggers Xendit Test Mode payment simulation server-side
  Future<String> simulateXenditPayment(String orderId) async {
    try {
      final resp = await _client.functions.invoke(
        'simulate-xendit-payment',
        body: {'order_id': orderId},
      );
      final data = resp.data;
      if (resp.status >= 400) {
        final msg = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Gagal memicu simulasi pembayaran.';
        throw Exception(msg);
      }
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Simulasi pembayaran Xendit terkirim.';
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }
      throw Exception(e.reasonPhrase ?? 'Simulasi pembayaran gagal.');
    }
  }

  /// Subscribes to Supabase Realtime Postgres Changes on both `orders` and `payments`
  /// for instant QRIS arrival and PAID_ACCEPTED notifications.
  /// Caller MUST call `unsubscribeChannel(channel)` in `dispose()`.
  RealtimeChannel subscribeToOrder({
    required String orderId,
    required VoidCallback onChange,
  }) {
    final channel = _client.channel('order-live-$orderId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();

    return channel;
  }

  Future<void> unsubscribeChannel(RealtimeChannel? channel) async {
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }
}
