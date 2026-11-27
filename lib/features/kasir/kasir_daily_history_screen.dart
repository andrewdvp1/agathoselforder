import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_exporter.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_progress_bar.dart';
import '../../core/widgets/glass_status_badge.dart';
import '../../core/widgets/payment_success_modal.dart';
import '../../core/widgets/pos_header.dart';
import '../../models/order_model.dart';
import '../../services/report_service.dart';

class KasirDailyHistoryScreen extends StatefulWidget {
  const KasirDailyHistoryScreen({super.key});

  @override
  State<KasirDailyHistoryScreen> createState() =>
      _KasirDailyHistoryScreenState();
}

class _KasirDailyHistoryScreenState extends State<KasirDailyHistoryScreen> {
  final _reportService = ReportService();
  final _searchCtrl = TextEditingController();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all | paid | pending | rejected

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _reportService.fetchCashierTodayHistory();
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

  List<OrderModel> get _filteredOrders {
    return _orders.where((o) {
      if (_statusFilter == 'paid' && o.status != OrderStatus.paidAccepted) {
        return false;
      }
      if (_statusFilter == 'pending' &&
          o.status != OrderStatus.pendingVerification &&
          o.status != OrderStatus.paymentProcessing) {
        return false;
      }
      if (_statusFilter == 'rejected' &&
          o.status != OrderStatus.rejected &&
          o.status != OrderStatus.expired) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = o.orderCode.toLowerCase().contains(q);
        final matchName = (o.customerName ?? '').toLowerCase().contains(q);
        final matchMethod = o.paymentMethodLabel.toLowerCase().contains(q);
        if (!matchCode && !matchName && !matchMethod) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final summary = ReportSummary.fromOrders(_orders);
    final todayLabel = AppFormatters.dateReadable(AppFormatters.todayWib());
    final successRatio =
        _orders.isEmpty ? 0.0 : summary.paidCount / _orders.length;
    final qrisRevenue = summary.revenueByMethod['QRIS'] ?? 0;
    final qrisShare = summary.totalRevenuePaid == 0
        ? 0
        : ((qrisRevenue / summary.totalRevenuePaid) * 100).round();

    final summaryRow = LayoutBuilder(
      builder: (context, c) {
        final cards = [
          GlassContainer(
            tier: GlassTier.level1,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Transaksi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfacePillInactive,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 15,
                        color: AppColors.slateHeader,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_orders.length} Pesanan',
                  style: AppFormatters.tabular(
                    theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniTag(
                      text: '${summary.paidCount} Sukses',
                      bg: AppColors.semanticSuccessSoft,
                      fg: AppColors.semanticSuccess,
                    ),
                    if (summary.rejectedCount > 0)
                      _MiniTag(
                        text: '${summary.rejectedCount} Batal',
                        bg: AppColors.semanticErrorSoft,
                        fg: AppColors.semanticError,
                      ),
                  ],
                ),
              ],
            ),
          ),
          GlassContainer(
            tier: GlassTier.level1,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Omzet (Lunas)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        size: 15,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.rupiah(summary.totalRevenuePaid),
                  style: AppFormatters.tabular(
                    theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniTag(
                      text: 'QRIS $qrisShare%',
                      bg: AppColors.semanticSuccessSoft,
                      fg: AppColors.semanticSuccess,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassProgressBar(
                        value: successRatio,
                        variant: GlassProgressVariant.secondary,
                        height: 5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];

        if (c.maxWidth > 320) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          );
        }
        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
          ],
        );
      },
    );

    final filtered = _filteredOrders;

    return RefreshIndicator(
      color: AppColors.accentTerracotta,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: _loadToday,
      child: CustomScrollView(
        slivers: [
          if (isMobile)
            SliverToBoxAdapter(
              child: PosSlateHeader(
                eyebrow: 'OPERASIONAL KASIR • WIB',
                title: 'Histori Pesanan Harian',
                subtitle: 'Hari Ini, $todayLabel (WIB)',
                trailing: PosHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Muat ulang histori hari ini',
                  onPressed: _loadToday,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Histori Pesanan Hari Ini',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tanggal operasional: $todayLabel (WIB)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    GlassCircularTonalIcon(
                      icon: Icons.refresh_rounded,
                      variant: TonalIconVariant.emerald,
                      tooltip: 'Muat ulang histori hari ini',
                      onPressed: _loadToday,
                    ),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : 24,
              16,
              isMobile ? 20 : 24,
              10,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summaryRow,
                  const SizedBox(height: 14),
                  // Quick Search
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari no. pesanan, nama pemesan, atau metode...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Semua (${_orders.length})',
                          active: _statusFilter == 'all',
                          onTap: () => setState(() => _statusFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Lunas (${summary.paidCount})',
                          active: _statusFilter == 'paid',
                          onTap: () => setState(() => _statusFilter = 'paid'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Menunggu (${summary.pendingOrOtherCount})',
                          active: _statusFilter == 'pending',
                          onTap: () =>
                              setState(() => _statusFilter = 'pending'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Ditolak (${summary.rejectedCount})',
                          active: _statusFilter == 'rejected',
                          onTap: () =>
                              setState(() => _statusFilter = 'rejected'),
                        ),
                      ],
                    ),
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
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _orders.isEmpty
                      ? 'Belum ada transaksi yang diproses hari ini.'
                      : 'Tidak ada pesanan yang cocok dengan filter.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 24,
                6,
                isMobile ? 20 : 24,
                32,
              ),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = filtered[index];
                  final isRejected = order.status == OrderStatus.rejected;
                  final itemsSummary = order.items
                      .map((e) => '${e.quantity}x ${e.menuNameSnapshot}')
                      .join(', ');

                  return GlassContainer(
                    tier: GlassTier.level1,
                    enableBlur: false,
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      if (order.status == OrderStatus.paidAccepted) {
                        PaymentSuccessModal.show(
                          context,
                          order: order,
                          isCashierView: true,
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        order.orderCode,
                                        style: AppFormatters.tabular(
                                          theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${AppFormatters.timeWib(order.createdAt)}',
                                        style: AppFormatters.tabular(
                                          theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.customerName ?? 'Pengunjung',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GlassStatusBadge(status: order.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: AppColors.bgCanvas,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (itemsSummary.isNotEmpty) ...[
                                Text(
                                  itemsSummary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Row(
                                children: [
                                  Icon(
                                    order.paymentMethodCode == 'QRIS'
                                        ? Icons.qr_code_2_rounded
                                        : Icons.payments_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Metode: ${order.paymentMethodLabel}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (order.rejectionReason != null)
                                    Text(
                                      '(${order.rejectionReason})',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.semanticError,
                                      ),
                                    ),
                                ],
                              ),
                              if (order.payment?.gatewayReference != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Ref: ${order.payment!.gatewayReference}',
                                  style: AppFormatters.tabular(
                                    theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isRejected
                                  ? 'Nominal Pembatalan'
                                  : 'Total Pembayaran',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              AppFormatters.rupiah(order.totalAmount),
                              style: AppFormatters.tabular(
                                theme.textTheme.titleMedium?.copyWith(
                                  color: isRejected
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  decoration: isRejected
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _MiniTag({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentTerracotta
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? AppColors.accentTerracotta
                  : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active ? Colors.white : AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}
