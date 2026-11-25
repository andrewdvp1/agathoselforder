import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_exporter.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_progress_bar.dart';
import '../../core/widgets/glass_status_badge.dart';
import '../../core/widgets/payment_success_modal.dart';
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
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadToday();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ReportSummary.fromOrders(_orders);
    final todayLabel = AppFormatters.dateReadable(AppFormatters.todayWib());
    final successRatio =
        _orders.isEmpty ? 0.0 : summary.paidCount / _orders.length;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceBase,
        onRefresh: _loadToday,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Histori Pesanan Hari Ini',
                                  style: theme.textTheme.headlineMedium),
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
                    const SizedBox(height: 16),

                    // Summary Metric Cards (Glass Level 1)
                    LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth > 540;
                        final cards = [
                          GlassContainer(
                            tier: GlassTier.level1,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Pembayaran Hari Ini (Lunas)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppFormatters.rupiah(summary.totalRevenuePaid),
                                  style: AppFormatters.tabular(
                                    theme.textTheme.headlineMedium?.copyWith(
                                      color: AppColors.secondaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GlassProgressBar(
                                  value: successRatio,
                                  variant: GlassProgressVariant.secondary,
                                ),
                              ],
                            ),
                          ),
                          GlassContainer(
                            tier: GlassTier.level1,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ringkasan Transaksi Hari Ini',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${summary.paidCount} Lunas / ${_orders.length} Total',
                                  style: AppFormatters.tabular(
                                    theme.textTheme.headlineSmall,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ditolak: ${summary.rejectedCount} • Lainnya: ${summary.pendingOrOtherCount}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];

                        if (isWide) {
                          return Row(
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
                    'Belum ada transaksi yang diproses hari ini.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 115),
                sliver: SliverList.separated(
                  itemCount: _orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return GlassContainer(
                      tier: GlassTier.level1,
                      enableBlur: false, // Pseudo-Glass for 60 FPS
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
                      child: Row(
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
                                          theme.textTheme.titleMedium),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.16),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        order.paymentMethodCode,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: AppColors.primaryTonal,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.customerName ?? 'Pengunjung'} • ${AppFormatters.timeWib(order.createdAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (order.payment?.gatewayReference != null)
                                  Text(
                                    'Ref: ${order.payment!.gatewayReference}',
                                    style: AppFormatters.tabular(
                                        theme.textTheme.bodySmall),
                                  ),
                                if (order.rejectionReason != null)
                                  Text(
                                    'Alasan: ${order.rejectionReason}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: AppColors.errorTonal),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GlassStatusBadge(
                                  status: order.status, compact: true),
                              const SizedBox(height: 8),
                              Text(
                                AppFormatters.rupiah(order.totalAmount),
                                style: AppFormatters.tabular(
                                  theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.tertiaryLight,
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
      ),
    );
  }
}
