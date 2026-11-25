import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_buttons.dart';
import 'glass_container.dart';

/// Real-Time Payment Success Modal (Glass Level 3 + Emerald Radial Glow)
/// Follows Design System Section 6.5 (3):
/// - User title: "Pembayaran Berhasil"
/// - Kasir title: "Pesanan Diterima & Pembayaran Berhasil"
class PaymentSuccessModal extends StatelessWidget {
  final OrderModel order;
  final bool isCashierView;
  final VoidCallback? onClose;

  const PaymentSuccessModal({
    super.key,
    required this.order,
    this.isCashierView = false,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required OrderModel order,
    bool isCashierView = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => PaymentSuccessModal(
        order: order,
        isCashierView: isCashierView,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isCashierView
        ? 'Pesanan Diterima &\nPembayaran Berhasil'
        : 'Pembayaran Berhasil';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassContainer(
          tier: GlassTier.level3,
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emerald Radial Glow + Checkmark
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.45),
                            AppColors.secondary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondaryLight,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.secondaryLight,
                        size: 38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  isCashierView
                      ? 'Pembayaran telah dikonfirmasi secara real-time. Pesanan siap diproses.'
                      : 'Terima kasih! Pesanan Anda telah lunas dan diterima kasir.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                // Summary Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGlassSubtle),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Nomor Pesanan',
                        value: order.orderCode,
                        isTabular: true,
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Metode Bayar',
                        value: order.paymentMethodLabel,
                      ),
                      if (order.payment?.gatewayReference != null) ...[
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Referensi Xendit',
                          value: order.payment!.gatewayReference!,
                          isTabular: true,
                        ),
                      ],
                      if (order.payment?.paidAt != null) ...[
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Waktu Lunas',
                          value: AppFormatters.dateTimeWib(order.payment!.paidAt!),
                          isTabular: true,
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Dibayar', style: theme.textTheme.titleMedium),
                          Text(
                            AppFormatters.rupiah(order.totalAmount),
                            style: AppFormatters.tabular(
                              theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassInvertedButton(
                  label: isCashierView ? 'Selesai & Kembali ke Scanner' : 'Selesai',
                  expand: true,
                  icon: Icons.check_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTabular;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isTabular = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isTabular ? AppFormatters.tabular(style) : style,
          ),
        ),
      ],
    );
  }
}
