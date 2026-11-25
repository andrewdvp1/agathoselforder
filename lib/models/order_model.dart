enum OrderStatus {
  pendingVerification('PENDING_VERIFICATION', 'Menunggu Verifikasi'),
  paymentProcessing('PAYMENT_PROCESSING', 'Menunggu Pembayaran'),
  paidAccepted('PAID_ACCEPTED', 'Pembayaran Berhasil'),
  rejected('REJECTED', 'Ditolak'),
  expired('EXPIRED', 'Kedaluwarsa');

  const OrderStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static OrderStatus fromDb(String? value) {
    switch (value?.toUpperCase()) {
      case 'PAYMENT_PROCESSING':
        return OrderStatus.paymentProcessing;
      case 'PAID_ACCEPTED':
        return OrderStatus.paidAccepted;
      case 'REJECTED':
        return OrderStatus.rejected;
      case 'EXPIRED':
        return OrderStatus.expired;
      default:
        return OrderStatus.pendingVerification;
    }
  }
}

enum PaymentStatus {
  pending('PENDING', 'Menunggu'),
  paid('PAID', 'Lunas'),
  failed('FAILED', 'Gagal'),
  expired('EXPIRED', 'Kedaluwarsa');

  const PaymentStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static PaymentStatus fromDb(String? value) {
    switch (value?.toUpperCase()) {
      case 'PAID':
        return PaymentStatus.paid;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'EXPIRED':
        return PaymentStatus.expired;
      default:
        return PaymentStatus.pending;
    }
  }
}

enum PaymentMethod {
  qris('QRIS', 'QRIS (Xendit)', 'QRIS', 'Scan dengan semua e-wallet & m-banking Indonesia', true),
  ovo('OVO', 'OVO', 'E-Wallet', 'Pembayaran instan via Xendit E-Wallet', false),
  dana('DANA', 'DANA', 'E-Wallet', 'Pembayaran instan via Xendit E-Wallet', false),
  shopeepay('SHOPEEPAY', 'ShopeePay', 'E-Wallet', 'Pembayaran instan via Xendit E-Wallet', false),
  linkaja('LINKAJA', 'LinkAja', 'E-Wallet', 'Pembayaran instan via Xendit E-Wallet', false),
  vaBca('VA_BCA', 'BCA Virtual Account', 'Virtual Account', 'Transfer otomatis via VA BCA (Xendit)', false),
  vaMandiri('VA_MANDIRI', 'Mandiri Virtual Account', 'Virtual Account', 'Transfer otomatis via VA Mandiri (Xendit)', false),
  vaBri('VA_BRI', 'BRI Virtual Account', 'Virtual Account', 'Transfer otomatis via VA BRI (Xendit)', false),
  vaBni('VA_BNI', 'BNI Virtual Account', 'Virtual Account', 'Transfer otomatis via VA BNI (Xendit)', false),
  cash('CASH', 'Tunai di Kasir', 'Non-Gateway', 'Bayar tunai langsung saat verifikasi kasir', false);

  const PaymentMethod(
    this.code,
    this.label,
    this.category,
    this.subtitle,
    this.isRecommended,
  );

  final String code;
  final String label;
  final String category;
  final String subtitle;
  final bool isRecommended;

  static PaymentMethod fromCode(String? code) {
    final normalized = code?.toUpperCase();
    for (final m in PaymentMethod.values) {
      if (m.code == normalized) return m;
    }
    return PaymentMethod.qris;
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String menuId;
  final String menuNameSnapshot;
  final int unitPriceSnapshot;
  final int quantity;
  final int subtotal;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuId,
    required this.menuNameSnapshot,
    required this.unitPriceSnapshot,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] as String?) ?? '',
      orderId: (json['order_id'] as String?) ?? '',
      menuId: (json['menu_id'] as String?) ?? '',
      menuNameSnapshot: (json['menu_name_snapshot'] as String?) ?? '-',
      unitPriceSnapshot: (json['unit_price_snapshot'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentModel {
  final String id;
  final String orderId;
  final String paymentMethod;
  final String gatewayProvider;
  final String? gatewayReference;
  final String? qrPayload;
  final String? paymentUrl;
  final int amount;
  final PaymentStatus status;
  final DateTime? paidAt;
  final String? verifiedByCashierId;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.gatewayProvider,
    this.gatewayReference,
    this.qrPayload,
    this.paymentUrl,
    required this.amount,
    required this.status,
    this.paidAt,
    this.verifiedByCashierId,
  });

  PaymentMethod get methodEnum => PaymentMethod.fromCode(paymentMethod);

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as String?) ?? '',
      orderId: (json['order_id'] as String?) ?? '',
      paymentMethod: (json['payment_method'] as String?) ?? 'QRIS',
      gatewayProvider: (json['gateway_provider'] as String?) ?? 'xendit',
      gatewayReference: json['gateway_reference'] as String?,
      qrPayload: json['qr_payload'] as String?,
      paymentUrl: json['payment_url'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: PaymentStatus.fromDb(json['status'] as String?),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      verifiedByCashierId: json['verified_by_cashier_id'] as String?,
    );
  }
}

class OrderModel {
  final String id;
  final String orderCode;
  final String qrToken;
  final String userId;
  final String? customerName;
  final String? cashierId;
  final String? cashierName;
  final int totalAmount;
  final OrderStatus status;
  final String? rejectionReason;
  final DateTime expiresAt;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final PaymentModel? payment;

  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.qrToken,
    required this.userId,
    this.customerName,
    this.cashierId,
    this.cashierName,
    required this.totalAmount,
    required this.status,
    this.rejectionReason,
    required this.expiresAt,
    required this.createdAt,
    this.items = const [],
    this.payment,
  });

  bool get isExpiredNow =>
      status == OrderStatus.expired ||
      (status == OrderStatus.pendingVerification &&
          DateTime.now().isAfter(expiresAt));

  String get paymentMethodLabel =>
      payment != null ? payment!.methodEnum.label : 'QRIS';

  String get paymentMethodCode => payment?.paymentMethod ?? 'QRIS';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['order_items'] ?? json['items']) as List<dynamic>? ?? [];
    final rawPayment = json['payment'] ?? json['payments'];
    PaymentModel? payment;
    if (rawPayment is Map<String, dynamic>) {
      payment = PaymentModel.fromJson(rawPayment);
    } else if (rawPayment is List && rawPayment.isNotEmpty) {
      payment = PaymentModel.fromJson(rawPayment.first as Map<String, dynamic>);
    }

    String? customerName = json['customer_name'] as String?;
    if (customerName == null && json['customer'] is Map<String, dynamic>) {
      customerName = (json['customer'] as Map<String, dynamic>)['full_name'] as String?;
    }

    String? cashierName = json['cashier_name'] as String?;
    if (cashierName == null && json['cashier'] is Map<String, dynamic>) {
      cashierName = (json['cashier'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return OrderModel(
      id: (json['id'] as String?) ?? '',
      orderCode: (json['order_code'] as String?) ?? '',
      qrToken: (json['qr_token'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      customerName: customerName,
      cashierId: json['cashier_id'] as String?,
      cashierName: cashierName,
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromDb(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(minutes: 20)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromJson)
          .toList(),
      payment: payment,
    );
  }
}
