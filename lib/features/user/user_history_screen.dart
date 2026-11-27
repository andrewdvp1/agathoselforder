import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_status_badge.dart';
import '../../core/widgets/pos_header.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class UserHistoryScreen extends StatefulWidget {
  final ValueChanged<OrderModel> onOpenActiveOrder;

  const UserHistoryScreen({
    super.key,
    required this.onOpenActiveOrder,
  });

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  final _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _orderService.fetchUserOrders();
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      color: AppColors.accentTerracotta,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: _loadHistory,
      child: CustomScrollView(
        slivers: [
          if (isMobile)
            SliverToBoxAdapter(
              child: PosSlateHeader(
                eyebrow: 'TRANSAKSI AKUN',
                title: 'Riwayat Pesanan Saya',
                subtitle:
                    'Hanya menampilkan transaksi milik akun Anda (dilindungi RLS).',
                trailing: PosHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Muat ulang riwayat',
                  onPressed: _loadHistory,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Pesanan Saya',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hanya menampilkan transaksi milik akun Anda (dilindungi RLS).',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    GlassCircularTonalIcon(
                      icon: Icons.refresh_rounded,
                      variant: TonalIconVariant.indigo,
                      onPressed: _loadHistory,
                    ),
                  ],
                ),
              ),
            ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentTerracotta,
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Text(_error!)),
            )
          else if (_orders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Belum ada riwayat pesanan.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 24,
                16,
                isMobile ? 20 : 24,
                32,
              ),
              sliver: SliverList.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _HistoryOrderCard(
                    order: order,
                    onOpenQr: () => widget.onOpenActiveOrder(order),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryOrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onOpenQr;

  const _HistoryOrderCard({
    required this.order,
    required this.onOpenQr,
  });

  @override
  State<_HistoryOrderCard> createState() => _HistoryOrderCardState();
}

class _HistoryOrderCardState extends State<_HistoryOrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final canReopenQr = order.status == OrderStatus.pendingVerification ||
        order.status == OrderStatus.paymentProcessing;

    return GlassContainer(
      tier: GlassTier.level1,
      enableBlur: false,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ctaDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.orderCode,
                  style: AppFormatters.tabular(
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppFormatters.dateTimeWib(order.createdAt),
                  overflow: TextOverflow.ellipsis,
                  style: AppFormatters.tabular(
                    theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GlassStatusBadge(status: order.status, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusProcessingSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.paymentMethodLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.statusProcessingText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.items.length} jenis item',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    AppFormatters.rupiah(order.totalAmount),
                    style: AppFormatters.tabular(
                      theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
          if (_expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (order.rejectionReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Alasan ditolak: ${order.rejectionReason}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.semanticError,
                      ),
                    ),
                  ],
                  if (order.payment?.gatewayReference != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Referensi Xendit: ${order.payment!.gatewayReference}',
                      style: AppFormatters.tabular(theme.textTheme.bodySmall),
                    ),
                  ],
                ],
              ),
            ),
            if (canReopenQr) ...[
              const SizedBox(height: 12),
              GlassPrimaryButton(
                label: 'Tampilkan QR & Status Live',
                icon: Icons.qr_code_2_rounded,
                onPressed: widget.onOpenQr,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
