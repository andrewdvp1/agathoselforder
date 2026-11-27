import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
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

  int get _totalQty =>
      widget.cartItems.fold(0, (sum, item) => sum + item.quantity);

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
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bgCanvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Deep Slate Blue Sheet Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.slateHeader, Color(0xFF273E4C)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Keranjang & Checkout',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentTerracotta,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$_totalQty Item',
                                        style: AppFormatters.tabular(
                                          const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Verifikasi item & pilih metode pembayaran Xendit',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSlateMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Daftar Pesanan Anda',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            children: List.generate(widget.cartItems.length, (i) {
                              final item = widget.cartItems[i];
                              final isLast = i == widget.cartItems.length - 1;
                              return Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.menu.name,
                                            style: theme.textTheme.labelLarge,
                                          ),
                                          Text(
                                            '${AppFormatters.rupiah(item.menu.price)} / item',
                                            style: AppFormatters.tabular(
                                              theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.rupiah(item.subtotal),
                                      style: AppFormatters.tabular(
                                        theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pilih Pembayaran Xendit',
                                style: theme.textTheme.titleMedium?.copyWith(
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
                                color: AppColors.semanticSuccessSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: AppColors.semanticSuccess,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Otomatis Realtime',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: AppColors.semanticSuccess,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        ...PaymentMethod.values.map((method) {
                          final active = _selectedMethod == method;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedMethod = method),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.accentSoft.withValues(alpha: 0.65)
                                        : AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: active
                                          ? AppColors.accentTerracotta
                                          : AppColors.borderSubtle,
                                      width: active ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? AppColors.accentTerracotta
                                              : AppColors.surfacePillInactive,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _iconForMethod(method),
                                          color: active
                                              ? Colors.white
                                              : AppColors.slateHeader,
                                          size: 20,
                                        ),
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
                                                    style: theme
                                                        .textTheme.labelLarge,
                                                  ),
                                                ),
                                                if (method.isRecommended) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.ctaDark,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        999,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Utama',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                            ? AppColors.accentTerracotta
                                            : AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: AppColors.accentTerracotta,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pembayaran diproses setelah kasir memindai & menyetujui QR Pesanan Anda.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Tagihan',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    '$_totalQty item • ${_selectedMethod.label}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                AppFormatters.rupiah(_total),
                                style: AppFormatters.tabular(
                                  theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.semanticErrorSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.statusErrorBorder,
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.semanticError,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        GlassPrimaryButton(
                          label:
                              'Buat Pesanan & Dapatkan QR • ${AppFormatters.rupiah(_total)}',
                          icon: Icons.qr_code_rounded,
                          loading: _submitting,
                          onPressed: _confirmOrder,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
