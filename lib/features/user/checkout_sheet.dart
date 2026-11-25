import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/cart_item.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class CheckoutSheet extends StatefulWidget {
  final List<CartItem> cartItems;
  final OrderService orderService;

  const CheckoutSheet({
    super.key,
    required this.cartItems,
    required this.orderService,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  PaymentMethod _selectedMethod = PaymentMethod.qris;
  bool _submitting = false;
  String? _error;

  int get _total =>
      widget.cartItems.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _confirmOrder() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order = await widget.orderService.createOrder(
        items: widget.cartItems,
        paymentMethod: _selectedMethod,
      );
      if (!mounted) return;
      Navigator.of(context).pop(order);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassContainer(
            tier: GlassTier.level3,
            borderRadius: 20,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Konfirmasi & Metode Pembayaran',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Cart items summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGlassSubtle),
                    ),
                    child: Column(
                      children: [
                        ...widget.cartItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.menu.name}',
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
                            Text('Total Pesanan',
                                style: theme.textTheme.titleMedium),
                            Text(
                              AppFormatters.rupiah(_total),
                              style: AppFormatters.tabular(
                                theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.tertiaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Pilih Metode Pembayaran (Xendit)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pembayaran akan diproses setelah kasir memindai & menyetujui QR Pesanan Anda.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...PaymentMethod.values.map((method) {
                    final active = _selectedMethod == method;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMethod = method),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.borderGlassSubtle,
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _iconForMethod(method),
                                  color: active
                                      ? AppColors.primaryTonal
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              method.label,
                                              style: theme.textTheme.labelLarge,
                                            ),
                                          ),
                                          if (method.isRecommended) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.statusPaidBg,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Direkomendasikan',
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.secondaryLight,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        method.subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  active
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.errorTonal),
                    ),
                  ],

                  const SizedBox(height: 14),
                  GlassPrimaryButton(
                    label: 'Buat Pesanan & Dapatkan QR',
                    icon: Icons.qr_code_rounded,
                    loading: _submitting,
                    onPressed: _confirmOrder,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForMethod(PaymentMethod method) {
    if (method == PaymentMethod.qris) return Icons.qr_code_2_rounded;
    if (method == PaymentMethod.cash) return Icons.payments_outlined;
    if (method.code.startsWith('VA_')) return Icons.account_balance_rounded;
    return Icons.account_balance_wallet_outlined;
  }
}
