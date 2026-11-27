import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_status_badge.dart';
import '../../core/widgets/payment_success_modal.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

/// Tactile Paper Level 3 Order Verification Bottom Sheet for Cashier.
/// Preserves Approve/Charge via Xendit, Reject with mandatory reason, and Realtime subscription.
class OrderVerificationSheet extends StatefulWidget {
  final OrderModel initialOrder;
  final VoidCallback onCompleted;

  const OrderVerificationSheet({
    super.key,
    required this.initialOrder,
    required this.onCompleted,
  });

  @override
  State<OrderVerificationSheet> createState() => _OrderVerificationSheetState();
}

class _OrderVerificationSheetState extends State<OrderVerificationSheet> {
  final _orderService = OrderService();
  final _reasonCtrl = TextEditingController();
  RealtimeChannel? _channel;

  late OrderModel _order;
  bool _approving = false;
  bool _rejecting = false;
  bool _showRejectInput = false;
  bool _simulating = false;
  bool _checking = false;
  bool _shownPaidModal = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    if (_order.status == OrderStatus.paymentProcessing) {
      _subscribeRealtime();
    }
  }

  void _subscribeRealtime() {
    if (_channel != null) return;
    _channel = _orderService.subscribeToOrder(
      orderId: _order.id,
      onChange: _refreshOrder,
    );
  }

  Future<void> _refreshOrder() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final latest = await _orderService.fetchOrderById(_order.id);
      if (!mounted) return;
      final becamePaid = latest.status == OrderStatus.paidAccepted;
      setState(() => _order = latest);

      if (becamePaid && !_shownPaidModal) {
        _shownPaidModal = true;
        widget.onCompleted();
        await PaymentSuccessModal.show(
          context,
          order: latest,
          isCashierView: true,
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {
      // Ignore transient realtime fetch errors; user can tap manual check
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _approveOrder() async {
    setState(() {
      _approving = true;
      _error = null;
    });
    try {
      final updated = await _orderService.approveAndChargeOrder(_order.id);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _approving = false;
      });
      widget.onCompleted();

      if (updated.status == OrderStatus.paidAccepted && !_shownPaidModal) {
        _shownPaidModal = true;
        await PaymentSuccessModal.show(
          context,
          order: updated,
          isCashierView: true,
        );
        if (mounted) Navigator.of(context).pop();
      } else {
        _subscribeRealtime();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _approving = false;
      });
    }
  }

  Future<void> _rejectOrder() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Alasan penolakan wajib diisi.');
      return;
    }

    setState(() {
      _rejecting = true;
      _error = null;
    });
    try {
      await _orderService.rejectOrder(orderId: _order.id, reason: reason);
      if (!mounted) return;
      widget.onCompleted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan ditolak dan tercatat di histori.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _rejecting = false;
      });
    }
  }

  Future<void> _simulatePayment() async {
    setState(() {
      _simulating = true;
      _error = null;
    });
    try {
      final msg = await _orderService.simulateXenditPayment(_order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted && _order.status != OrderStatus.paidAccepted) {
        await _refreshOrder();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _orderService.unsubscribeChannel(_channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canApproveOrReject =
        _order.status == OrderStatus.pendingVerification && !_order.isExpiredNow;
    final isProcessing = _order.status == OrderStatus.paymentProcessing;
    final isExpired = _order.isExpiredNow;
    final alreadyDone = _order.status == OrderStatus.paidAccepted ||
        _order.status == OrderStatus.rejected;
    final effectiveStatus = isExpired ? OrderStatus.expired : _order.status;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Verifikasi Pesanan',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ctaDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _order.orderCode,
                          style: AppFormatters.tabular(
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_order.customerName ?? 'Pengunjung'} • ${AppFormatters.timeWib(_order.createdAt)}',
                          style: AppFormatters.tabular(
                            theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      GlassStatusBadge(status: effectiveStatus, compact: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Payment & Total Summary Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgCanvas,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _order.paymentMethodLabel,
                                style: theme.textTheme.labelLarge,
                              ),
                              if (_order.payment?.gatewayReference != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Ref: ${_order.payment!.gatewayReference!}',
                                  style: AppFormatters.tabular(
                                    theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Tagihan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              AppFormatters.rupiah(_order.totalAmount),
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

                  const SizedBox(height: 16),
                  Text(
                    'Item Pesanan (${_order.items.length})',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),

                  ..._order.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderDefault),
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

                  const SizedBox(height: 10),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.semanticErrorSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusErrorBorder),
                      ),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.semanticError,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isExpired)
                    const _WarningBanner(
                      icon: Icons.timer_off_rounded,
                      bg: AppColors.semanticErrorSoft,
                      border: AppColors.statusErrorBorder,
                      fg: AppColors.semanticError,
                      text:
                          'QR Pesanan telah kedaluwarsa. Minta pengunjung membuat pesanan baru.',
                    )
                  else if (alreadyDone)
                    _WarningBanner(
                      icon: Icons.info_outline_rounded,
                      bg: AppColors.semanticWarningSoft,
                      border: AppColors.statusPendingBorder,
                      fg: AppColors.statusPendingText,
                      text:
                          'Pesanan sudah diproses/selesai (${_order.status.label}). Double-scan ditolak.',
                    )
                  else if (isProcessing) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.statusProcessingSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.statusProcessingBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.statusProcessingText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Menunggu Konfirmasi Webhook Xendit...',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.statusProcessingText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tagihan ${_order.paymentMethodLabel} telah dikirim ke layar pengunjung. Halaman ini akan otomatis diperbarui via Supabase Realtime.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (SupabaseConfig.isTestMode) ...[
                      GlassPrimaryButton(
                        label: 'Simulasi Pelunasan (Xendit Test Mode)',
                        icon: Icons.bolt_rounded,
                        customColor: AppColors.semanticSuccess,
                        loading: _simulating,
                        onPressed: _simulatePayment,
                      ),
                      const SizedBox(height: 10),
                    ],
                    GlassOutlinedButton(
                      label: _checking
                          ? 'Memeriksa...'
                          : 'Cek Status Pembayaran',
                      icon: Icons.sync_rounded,
                      expand: true,
                      onPressed: _checking ? null : _refreshOrder,
                    ),
                  ] else if (canApproveOrReject) ...[
                    if (_showRejectInput) ...[
                      TextField(
                        controller: _reasonCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alasan Penolakan (Wajib)',
                          hintText: 'Contoh: Stok menu habis atau gerai tutup',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassOutlinedButton(
                              label: 'Batal',
                              onPressed: () =>
                                  setState(() => _showRejectInput = false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GlassPrimaryButton(
                              label: 'Konfirmasi Tolak',
                              customColor: AppColors.semanticError,
                              loading: _rejecting,
                              onPressed: _rejectOrder,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      GlassPrimaryButton(
                        label: 'Setujui Pesanan & Pembayaran',
                        icon: Icons.check_circle_outline_rounded,
                        loading: _approving,
                        onPressed: _approveOrder,
                      ),
                      const SizedBox(height: 10),
                      GlassOutlinedButton(
                        label: 'Tolak Pesanan',
                        icon: Icons.cancel_outlined,
                        isDestructive: true,
                        expand: true,
                        onPressed: _approving
                            ? null
                            : () => setState(() => _showRejectInput = true),
                      ),
                    ],
                  ],

                  const SizedBox(height: 10),
                  GlassSecondaryButton(
                    label: 'Tutup',
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color border;
  final Color fg;
  final String text;

  const _WarningBanner({
    required this.icon,
    required this.bg,
    required this.border,
    required this.fg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
