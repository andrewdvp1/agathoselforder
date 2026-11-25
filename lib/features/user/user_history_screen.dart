import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_status_badge.dart';
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
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceBase,
        onRefresh: _loadHistory,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Riwayat Pesanan Saya',
                              style: theme.textTheme.headlineMedium),
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
                    child: CircularProgressIndicator(color: AppColors.primary)),
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
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 115),
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
      enableBlur: false, // Pseudo-Glass for 60 FPS list scrolling
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderCode,
                      style: AppFormatters.tabular(theme.textTheme.titleMedium),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.dateTimeWib(order.createdAt)} • ${order.paymentMethodLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GlassStatusBadge(status: order.status, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} jenis item',
                style: theme.textTheme.bodyMedium,
              ),
              Row(
                children: [
                  Text(
                    AppFormatters.rupiah(order.totalAmount),
                    style: AppFormatters.tabular(
                      theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.tertiaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                      style: AppFormatters.tabular(theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            if (order.rejectionReason != null) ...[
              const SizedBox(height: 6),
              Text(
                'Alasan ditolak: ${order.rejectionReason}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.errorTonal),
              ),
            ],
            if (order.payment?.gatewayReference != null) ...[
              const SizedBox(height: 6),
              Text(
                'Referensi Xendit: ${order.payment!.gatewayReference}',
                style: AppFormatters.tabular(theme.textTheme.bodySmall),
              ),
            ],
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
