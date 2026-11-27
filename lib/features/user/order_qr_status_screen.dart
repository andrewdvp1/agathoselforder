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
import '../../core/widgets/pos_header.dart';
import '../../core/widgets/qr_display_card.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

/// Live Order QR & Payment Status screen for User.
/// Preserves Supabase Realtime (`orders` & `payments`) + lifecycle auto-refresh.
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
  int _activeTab = 0; // 0: QR & Status, 1: Rincian Pesanan

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
      _activeTab = 0;
      _bindOrder(widget.initialOrder);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
            backgroundColor: AppColors.semanticSuccess,
            content: Text(
              'Pembayaran Berhasil! Pesanan Anda telah diterima kasir.',
              style: TextStyle(
                color: Colors.white,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
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
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 36,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Pesanan Aktif',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih menu di katalog terlebih dahulu untuk membuat QR Code Pesanan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
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
    final effectiveStatus = isExpired ? OrderStatus.expired : order.status;

    final segmentedTabs = PosSegmentedTabs(
      elevated: isMobile,
      selectedIndex: _activeTab,
      onSelect: (idx) => setState(() => _activeTab = idx),
      items: const [
        PosSegmentedTabItem(
          label: 'QR & Status',
          icon: Icons.qr_code_2_rounded,
        ),
        PosSegmentedTabItem(
          label: 'Rincian Pesanan',
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );

    final mainContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, isMobile ? 16 : 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isMobile) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Pesanan',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.orderCode,
                            style: AppFormatters.tabular(
                              theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.slateHeader,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassStatusBadge(status: effectiveStatus),
                  ],
                ),
                const SizedBox(height: 16),
                segmentedTabs,
                const SizedBox(height: 16),
              ],

              if (_activeTab == 0) ...[
                // Status Pill Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Terkini',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GlassStatusBadge(status: effectiveStatus),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. PENDING_VERIFICATION -> Order QR Code
                if (isPending)
                  QrDisplayCard(
                    title: 'Kode Pesanan',
                    subtitle:
                        'Tunjukkan QR ini ke kasir untuk diverifikasi sebelum pembayaran (${order.paymentMethodLabel}).',
                    qrData: order.qrToken,
                    orderCode: order.orderCode,
                    totalAmount: order.totalAmount,
                    remainingDuration: _remaining,
                    badge: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ctaDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Scan di Kasir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusProcessingSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.statusProcessingBorder,
                          ),
                        ),
                        child: Text(
                          'QRIS Aktif',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.statusProcessingText,
                          ),
                        ),
                      ),
                    )
                  else
                    GlassContainer(
                      tier: GlassTier.level1,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.statusProcessingSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payment_rounded,
                              size: 28,
                              color: AppColors.statusProcessingText,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
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
                      customColor: AppColors.semanticSuccess,
                      loading: _simulating,
                      onPressed: _simulatePayment,
                    ),
                  ],
                ],

                // 3. PAID_ACCEPTED
                if (isPaid)
                  GlassContainer(
                    tier: GlassTier.level1,
                    borderColor: AppColors.statusPaidBorder,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.semanticSuccessSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 42,
                            color: AppColors.semanticSuccess,
                          ),
                        ),
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
                              color: AppColors.semanticSuccess,
                            ),
                          ),
                        ),
                        if (order.payment?.gatewayReference != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Ref Xendit: ${order.payment!.gatewayReference}',
                            style: AppFormatters.tabular(
                              theme.textTheme.bodySmall,
                            ),
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
                    tier: GlassTier.level1,
                    borderColor: AppColors.statusErrorBorder,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.semanticErrorSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cancel_rounded,
                            size: 36,
                            color: AppColors.semanticError,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pesanan Ditolak Kasir',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Alasan: ${order.rejectionReason ?? 'Stok tidak tersedia'}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.semanticError,
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
                    tier: GlassTier.level1,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.surfacePillInactive,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer_off_rounded,
                            size: 34,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'QR Pesanan Kedaluwarsa',
                          style: theme.textTheme.headlineSmall,
                        ),
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

                // Dynamic Order Progress Timeline Card
                _OrderProgressTimeline(
                  order: order,
                  isExpired: isExpired,
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
              ] else ...[
                // Tab 1: Rincian Pesanan
                GlassContainer(
                  tier: GlassTier.level1,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rincian Pesanan',
                            style: theme.textTheme.titleLarge,
                          ),
                          GlassStatusBadge(
                            status: effectiveStatus,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.orderCode} • ${AppFormatters.dateTimeWib(order.createdAt)}',
                        style: AppFormatters.tabular(
                          theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfacePillInactive,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.quantity}x',
                                  style: AppFormatters.tabular(
                                    theme.textTheme.labelMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.menuNameSnapshot,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                AppFormatters.rupiah(item.subtotal),
                                style: AppFormatters.tabular(
                                  theme.textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      _SummaryInfoRow(
                        label: 'Metode Pembayaran',
                        value: order.paymentMethodLabel,
                      ),
                      if (order.payment?.gatewayReference != null) ...[
                        const SizedBox(height: 8),
                        _SummaryInfoRow(
                          label: 'Referensi Xendit',
                          value: order.payment!.gatewayReference!,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Tagihan',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            AppFormatters.rupiah(order.totalAmount),
                            style: AppFormatters.tabular(
                              theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          PosSlateHeader(
            eyebrow: 'REALTIME TERHUBUNG',
            title: 'Status Pembayaran',
            subtitle: '${order.orderCode} • ${order.paymentMethodLabel}',
            trailing: PosHeaderIconButton(
              icon: Icons.sync_rounded,
              tooltip: 'Cek status',
              onPressed: _checking ? () {} : _refreshOrder,
            ),
            straddleOverlap: 24,
            straddlingChild: segmentedTabs,
          ),
          Expanded(
            child: SingleChildScrollView(child: mainContent),
          ),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(child: mainContent),
    );
  }
}

class _OrderProgressTimeline extends StatelessWidget {
  final OrderModel order;
  final bool isExpired;

  const _OrderProgressTimeline({
    required this.order,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = order.status == OrderStatus.paidAccepted;
    final isRejected = order.status == OrderStatus.rejected;
    final isProcessing = order.status == OrderStatus.paymentProcessing;

    return GlassContainer(
      tier: GlassTier.level1,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres Pesanan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _TimelineStep(
            title: 'Pesanan Dibuat',
            subtitle: 'Item diteruskan ke kasir untuk verifikasi QR',
            timeLabel: AppFormatters.timeWib(order.createdAt),
            state: _StepState.done,
            showLine: true,
          ),
          _TimelineStep(
            title: isRejected
                ? 'Pesanan Ditolak'
                : (isExpired
                    ? 'QR Kedaluwarsa'
                    : (isProcessing
                        ? 'Menunggu Pembayaran (${order.paymentMethodLabel})'
                        : 'Verifikasi Kasir')),
            subtitle: isRejected
                ? (order.rejectionReason ?? 'Ditolak oleh kasir')
                : (isExpired
                    ? 'Batas waktu QR berakhir'
                    : (isProcessing
                        ? 'Selesaikan pembayaran via Xendit'
                        : (isPaid
                            ? 'Pesanan diverifikasi kasir'
                            : 'Tunjukkan QR ke kasir'))),
            badgeText: (!isPaid && !isRejected && !isExpired)
                ? 'Sedang Berjalan'
                : null,
            state: isPaid
                ? _StepState.done
                : (isRejected || isExpired
                    ? _StepState.error
                    : _StepState.active),
            showLine: true,
          ),
          _TimelineStep(
            title: 'Pembayaran Diterima',
            subtitle: isPaid
                ? 'Pembayaran lunas & pesanan siap diproses'
                : 'Menunggu konfirmasi lunas otomatis',
            timeLabel: order.payment?.paidAt != null
                ? AppFormatters.timeWib(order.payment!.paidAt!)
                : null,
            state: isPaid ? _StepState.done : _StepState.upcoming,
            showLine: false,
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, error, upcoming }

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? timeLabel;
  final String? badgeText;
  final _StepState state;
  final bool showLine;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    this.timeLabel,
    this.badgeText,
    required this.state,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color dotBg;
    Color dotFg;
    IconData? icon;

    switch (state) {
      case _StepState.done:
        dotBg = AppColors.semanticSuccess;
        dotFg = Colors.white;
        icon = Icons.check_rounded;
      case _StepState.active:
        dotBg = AppColors.accentSoft;
        dotFg = AppColors.accentTerracotta;
        icon = Icons.circle;
      case _StepState.error:
        dotBg = AppColors.semanticErrorSoft;
        dotFg = AppColors.semanticError;
        icon = Icons.close_rounded;
      case _StepState.upcoming:
        dotBg = AppColors.surfacePillInactive;
        dotFg = AppColors.textMuted;
        icon = Icons.circle;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: state == _StepState.active || state == _StepState.upcoming
                        ? 9
                        : 14,
                    color: dotFg,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: state == _StepState.done
                          ? AppColors.semanticSuccess.withValues(alpha: 0.4)
                          : AppColors.borderDefault,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 14 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: state == _StepState.upcoming
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              color: AppColors.accentTerracotta,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (timeLabel != null)
                        Text(
                          timeLabel!,
                          style: AppFormatters.tabular(
                            theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: state == _StepState.upcoming
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: AppFormatters.tabular(
            theme.textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}
