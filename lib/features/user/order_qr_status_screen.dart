import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_status_badge.dart';
import '../../core/widgets/payment_success_modal.dart';
import '../../core/widgets/qr_display_card.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

/// Live Order QR & Payment Status screen for User.
/// - Subscribes to Supabase Realtime (`orders` & `payments`)
/// - Unsubscribes on `dispose()`
/// - Auto-refetches on `AppLifecycleState.resumed` (PRD Section 7)
/// - Shows Order QR (`PENDING_VERIFICATION`) -> Xendit QRIS (`PAYMENT_PROCESSING`)
///   -> Real-time "Pembayaran Berhasil" modal (`PAID_ACCEPTED`)
class OrderQrStatusScreen extends StatefulWidget {
  final OrderModel? initialOrder;
  final VoidCallback onCreateNewOrder;
  final ValueChanged<OrderModel>? onOrderUpdated;

  const OrderQrStatusScreen({
    super.key,
    required this.initialOrder,
    required this.onCreateNewOrder,
    this.onOrderUpdated,
  });

  @override
  State<OrderQrStatusScreen> createState() => _OrderQrStatusScreenState();
}

class _OrderQrStatusScreenState extends State<OrderQrStatusScreen>
    with WidgetsBindingObserver {
  final _orderService = OrderService();
  RealtimeChannel? _channel;
  Timer? _countdownTimer;

  OrderModel? _order;
  Duration _remaining = Duration.zero;
  bool _checking = false;
  bool _simulating = false;
  bool _hasShownPaidModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindOrder(widget.initialOrder);
  }

  @override
  void didUpdateWidget(covariant OrderQrStatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOrder?.id != widget.initialOrder?.id) {
      _hasShownPaidModal = false;
      _bindOrder(widget.initialOrder);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-refresh when Android app returns from background or Web tab resumes
    if (state == AppLifecycleState.resumed && _order != null) {
      _refreshOrder();
    }
  }

  Future<void> _bindOrder(OrderModel? order) async {
    await _orderService.unsubscribeChannel(_channel);
    _channel = null;
    _countdownTimer?.cancel();

    setState(() {
      _order = order;
      _updateRemaining();
    });

    if (order == null) return;

    _channel = _orderService.subscribeToOrder(
      orderId: order.id,
      onChange: _refreshOrder,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_updateRemaining);
    });
  }

  void _updateRemaining() {
    final o = _order;
    if (o == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = o.expiresAt.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _refreshOrder() async {
    final current = _order;
    if (current == null || _checking) return;

    setState(() => _checking = true);
    try {
      final latest = await _orderService.fetchOrderById(current.id);
      if (!mounted) return;
      final becamePaid = current.status != OrderStatus.paidAccepted &&
          latest.status == OrderStatus.paidAccepted;

      setState(() {
        _order = latest;
        _updateRemaining();
      });
      widget.onOrderUpdated?.call(latest);

      if (becamePaid && !_hasShownPaidModal) {
        _hasShownPaidModal = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text(
              'Pembayaran Berhasil! Pesanan Anda telah diterima kasir.',
              style: TextStyle(
                color: AppColors.neutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        await PaymentSuccessModal.show(
          context,
          order: latest,
          isCashierView: false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memeriksa status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _simulatePayment() async {
    final order = _order;
    if (order == null) return;
    setState(() => _simulating = true);
    try {
      final msg = await _orderService.simulateXenditPayment(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      // Give webhook a moment then ensure UI updates even if WS was slow
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted && _order?.status != OrderStatus.paidAccepted) {
        await _refreshOrder();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _orderService.unsubscribeChannel(_channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = _order;

    if (order == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: GlassContainer(
                tier: GlassTier.level1,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        size: 54, color: AppColors.primaryTonal),
                    const SizedBox(height: 14),
                    Text('Belum Ada Pesanan Aktif',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih menu di katalog terlebih dahulu untuk membuat QR Code Pesanan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    GlassPrimaryButton(
                      label: 'Buka Katalog Menu',
                      icon: Icons.restaurant_menu_rounded,
                      onPressed: widget.onCreateNewOrder,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isPending = order.status == OrderStatus.pendingVerification &&
        !order.isExpiredNow;
    final isProcessing = order.status == OrderStatus.paymentProcessing;
    final isPaid = order.status == OrderStatus.paidAccepted;
    final isRejected = order.status == OrderStatus.rejected;
    final isExpired = order.isExpiredNow;
    final qrisPayload = order.payment?.qrPayload;
    final paymentUrl = order.payment?.paymentUrl;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 115),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Status Pesanan',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    GlassStatusBadge(status: isExpired ? OrderStatus.expired : order.status),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. PENDING_VERIFICATION -> Order QR Code
                if (isPending)
                  QrDisplayCard(
                    title: 'QR Code Pesanan',
                    subtitle:
                        'Tunjukkan QR ini ke kasir untuk diverifikasi sebelum pembayaran (${order.paymentMethodLabel}).',
                    qrData: order.qrToken,
                    orderCode: order.orderCode,
                    totalAmount: order.totalAmount,
                    remainingDuration: _remaining,
                    badge: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusPendingBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Scan di Kasir',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: AppColors.tertiaryLight),
                      ),
                    ),
                  ),

                // 2. PAYMENT_PROCESSING -> Xendit QRIS / Payment Instructions
                if (isProcessing) ...[
                  if (qrisPayload != null && qrisPayload.isNotEmpty)
                    QrDisplayCard(
                      title: 'QRIS Pembayaran (Xendit)',
                      subtitle:
                          'Kasir telah menyetujui pesanan! Pindai QRIS berikut untuk melunasi pembayaran secara real-time.',
                      qrData: qrisPayload,
                      orderCode: order.orderCode,
                      totalAmount: order.totalAmount,
                      remainingDuration: _remaining,
                      badge: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusProcessingBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'QRIS Aktif',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: AppColors.primaryTonal),
                        ),
                      ),
                    )
                  else
                    GlassContainer(
                      tier: GlassTier.level2,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.payment_rounded,
                              size: 46, color: AppColors.primaryTonal),
                          const SizedBox(height: 10),
                          Text(
                            'Tagihan ${order.paymentMethodLabel} Siap',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Selesaikan pembayaran melalui halaman Xendit untuk mengonfirmasi pesanan.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppFormatters.rupiah(order.totalAmount),
                            style: AppFormatters.tabular(
                              theme.textTheme.displaySmall,
                            ),
                          ),
                          if (paymentUrl != null) ...[
                            const SizedBox(height: 16),
                            GlassPrimaryButton(
                              label: 'Buka Halaman Pembayaran Xendit',
                              icon: Icons.open_in_new_rounded,
                              onPressed: () async {
                                final uri = Uri.tryParse(paymentUrl);
                                if (uri != null) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (SupabaseConfig.isTestMode) ...[
                    const SizedBox(height: 12),
                    GlassPrimaryButton(
                      label: 'Simulasi Bayar (Xendit Test Mode)',
                      icon: Icons.bolt_rounded,
                      customColor: AppColors.secondary,
                      loading: _simulating,
                      onPressed: _simulatePayment,
                    ),
                  ],
                ],

                // 3. PAID_ACCEPTED
                if (isPaid)
                  GlassContainer(
                    tier: GlassTier.level2,
                    borderColor: AppColors.secondary.withValues(alpha: 0.55),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 56, color: AppColors.secondaryLight),
                        const SizedBox(height: 12),
                        Text(
                          'Pembayaran Berhasil',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pesanan ${order.orderCode} telah lunas dan diterima kasir.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppFormatters.rupiah(order.totalAmount),
                          style: AppFormatters.tabular(
                            theme.textTheme.displaySmall?.copyWith(
                              color: AppColors.secondaryLight,
                            ),
                          ),
                        ),
                        if (order.payment?.gatewayReference != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Ref Xendit: ${order.payment!.gatewayReference}',
                            style: AppFormatters.tabular(
                                theme.textTheme.bodySmall),
                          ),
                        ],
                        const SizedBox(height: 18),
                        GlassPrimaryButton(
                          label: 'Pesan Menu Lagi',
                          icon: Icons.add_shopping_cart_rounded,
                          onPressed: widget.onCreateNewOrder,
                        ),
                      ],
                    ),
                  ),

                // 4. REJECTED
                if (isRejected)
                  GlassContainer(
                    tier: GlassTier.level2,
                    borderColor: AppColors.error.withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.cancel_rounded,
                            size: 52, color: AppColors.errorLight),
                        const SizedBox(height: 12),
                        Text('Pesanan Ditolak Kasir',
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Alasan: ${order.rejectionReason ?? 'Stok tidak tersedia'}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.errorTonal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassPrimaryButton(
                          label: 'Buat Pesanan Baru',
                          onPressed: widget.onCreateNewOrder,
                        ),
                      ],
                    ),
                  ),

                // 5. EXPIRED
                if (isExpired)
                  GlassContainer(
                    tier: GlassTier.level2,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.timer_off_rounded,
                            size: 52, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('QR Pesanan Kedaluwarsa',
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text(
                          'Batas waktu QR telah berakhir sebelum diproses kasir. Silakan buat pesanan baru.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        GlassPrimaryButton(
                          label: 'Buat Pesanan Ulang',
                          onPressed: widget.onCreateNewOrder,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Order Items Breakdown
                GlassContainer(
                  tier: GlassTier.level1,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rincian Pesanan', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 10),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.menuNameSnapshot}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                AppFormatters.rupiah(item.subtotal),
                                style: AppFormatters.tabular(
                                  theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Metode Pembayaran',
                              style: theme.textTheme.bodyMedium),
                          Text(order.paymentMethodLabel,
                              style: theme.textTheme.labelLarge),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isPending || isProcessing) ...[
                  const SizedBox(height: 14),
                  GlassOutlinedButton(
                    label: _checking
                        ? 'Memeriksa Status...'
                        : 'Cek Status Pembayaran',
                    icon: Icons.sync_rounded,
                    expand: true,
                    onPressed: _checking ? null : _refreshOrder,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
