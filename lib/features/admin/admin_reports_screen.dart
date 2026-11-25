import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_exporter.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_progress_bar.dart';
import '../../core/widgets/glass_status_badge.dart';
import '../../models/order_model.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _reportService = ReportService();
  final _authService = AuthService();

  DateTime _startDate = AppFormatters.todayWib();
  DateTime _endDate = AppFormatters.todayWib();
  String? _selectedCashierId;
  OrderStatus? _selectedStatus;
  String? _selectedPaymentMethod;

  List<UserProfile> _cashiers = [];
  List<OrderModel> _orders = [];
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final cashiers = await _authService.fetchCashiers();
      if (mounted) setState(() => _cashiers = cashiers);
    } catch (_) {
      // Non-fatal if cashier list fails initially
    }
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _reportService.fetchOrdersReport(
        startDate: _startDate,
        endDate: _endDate,
        cashierId: _selectedCashierId,
        status: _selectedStatus,
        paymentMethod: _selectedPaymentMethod,
      );
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: AppFormatters.todayWib().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceBase,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadOrders();
    }
  }

  Future<void> _export(ReportFormat format) async {
    setState(() => _exporting = true);
    try {
      final msg = await ReportExporter.exportReport(
        orders: _orders,
        startDate: _startDate,
        endDate: _endDate,
        format: format,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh laporan: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ReportSummary.fromOrders(_orders);
    final isWide = MediaQuery.of(context).size.width > 860;
    final dateLabel = AppFormatters.isoDate(_startDate) ==
            AppFormatters.isoDate(_endDate)
        ? AppFormatters.dateReadable(_startDate)
        : '${AppFormatters.dateReadable(_startDate)} – ${AppFormatters.dateReadable(_endDate)}';

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceBase,
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 115),
          children: [
            // Header + Export Menu
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard & Laporan Harian',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Agregasi transaksi seluruh kasir berdasarkan zona waktu WIB (Asia/Jakarta).',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                PopupMenuButton<ReportFormat>(
                  enabled: !_exporting,
                  color: AppColors.surfaceBase,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderGlassMedium),
                  ),
                  onSelected: _export,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: ReportFormat.xlsx,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.table_chart_rounded,
                            color: AppColors.secondaryLight),
                        title: Text('Unduh Excel (.xlsx)'),
                      ),
                    ),
                    PopupMenuItem(
                      value: ReportFormat.csv,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.description_outlined,
                            color: AppColors.primaryTonal),
                        title: Text('Unduh CSV (.csv)'),
                      ),
                    ),
                    PopupMenuItem(
                      value: ReportFormat.pdf,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.picture_as_pdf_rounded,
                            color: AppColors.errorLight),
                        title: Text('Unduh PDF (.pdf)'),
                      ),
                    ),
                  ],
                  child: IgnorePointer(
                    child: GlassInvertedButton(
                      label: _exporting ? 'Menyiapkan...' : 'Unduh Laporan',
                      icon: Icons.download_rounded,
                      loading: _exporting,
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Filter Panel (Glass Level 1)
            GlassContainer(
              tier: GlassTier.level1,
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GlassSecondaryButton(
                    label: 'Tanggal: $dateLabel',
                    icon: Icons.calendar_today_rounded,
                    onPressed: _pickDateRange,
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedCashierId,
                      dropdownColor: AppColors.surfaceBase,
                      decoration: const InputDecoration(
                        labelText: 'Kasir',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Kasir'),
                        ),
                        ..._cashiers.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.fullName),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCashierId = val);
                        _loadOrders();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<OrderStatus?>(
                      initialValue: _selectedStatus,
                      dropdownColor: AppColors.surfaceBase,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<OrderStatus?>(
                          value: null,
                          child: Text('Semua Status'),
                        ),
                        ...OrderStatus.values.map(
                          (s) => DropdownMenuItem<OrderStatus?>(
                            value: s,
                            child: Text(s.label),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedStatus = val);
                        _loadOrders();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedPaymentMethod,
                      dropdownColor: AppColors.surfaceBase,
                      decoration: const InputDecoration(
                        labelText: 'Metode Bayar',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Metode'),
                        ),
                        ...PaymentMethod.values.map(
                          (m) => DropdownMenuItem<String?>(
                            value: m.code,
                            child: Text(m.code),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedPaymentMethod = val);
                        _loadOrders();
                      },
                    ),
                  ),
                  GlassCircularTonalIcon(
                    icon: Icons.refresh_rounded,
                    variant: TonalIconVariant.indigo,
                    tooltip: 'Muat ulang laporan',
                    onPressed: _loadOrders,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metric Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 960
                    ? 4
                    : (constraints.maxWidth > 540 ? 2 : 1);
                final qrisTotal = summary.revenueByMethod['QRIS'] ?? 0;
                final qrisRatio = summary.totalRevenuePaid == 0
                    ? 0.0
                    : qrisTotal / summary.totalRevenuePaid;

                final metricCards = [
                  _MetricCard(
                    title: 'Total Omzet (PAID_ACCEPTED)',
                    value: AppFormatters.rupiah(summary.totalRevenuePaid),
                    accent: AppColors.secondaryLight,
                    subtitle: '100% cocok dengan PostgreSQL',
                  ),
                  _MetricCard(
                    title: 'Transaksi Berhasil',
                    value: '${summary.paidCount}',
                    accent: AppColors.primaryTonal,
                    subtitle: 'Dari ${_orders.length} total pesanan',
                  ),
                  _MetricCard(
                    title: 'Transaksi Ditolak',
                    value: '${summary.rejectedCount}',
                    accent: AppColors.errorLight,
                    subtitle: 'Pending/Expired: ${summary.pendingOrOtherCount}',
                  ),
                  _MetricCard(
                    title: 'Total QRIS (Xendit)',
                    value: AppFormatters.rupiah(qrisTotal),
                    accent: AppColors.tertiaryLight,
                    subtitle:
                        '${(qrisRatio * 100).toStringAsFixed(0)}% dari total omzet',
                    progress: qrisRatio,
                  ),
                ];

                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 2.6 : 1.75,
                  children: metricCards,
                );
              },
            ),

            // Payment Method Breakdown
            if (summary.revenueByMethod.isNotEmpty) ...[
              const SizedBox(height: 16),
              GlassContainer(
                tier: GlassTier.level1,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pemecahan per Metode Pembayaran (PAID)',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...summary.revenueByMethod.entries.map((entry) {
                      final ratio = summary.totalRevenuePaid == 0
                          ? 0.0
                          : entry.value / summary.totalRevenuePaid;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${entry.key} (${summary.countByMethod[entry.key] ?? 0} trx)',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.textPrimary),
                                ),
                                Text(
                                  AppFormatters.rupiah(entry.value),
                                  style: AppFormatters.tabular(
                                    theme.textTheme.labelLarge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            GlassProgressBar(
                              value: ratio,
                              variant: entry.key == 'QRIS'
                                  ? GlassProgressVariant.secondary
                                  : GlassProgressVariant.primary,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Orders Table / List
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              GlassContainer(
                tier: GlassTier.level1,
                padding: const EdgeInsets.all(20),
                child: Text(_error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.errorTonal)),
              )
            else if (_orders.isEmpty)
              GlassContainer(
                tier: GlassTier.level1,
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    'Tidak ada transaksi pada rentang tanggal & filter yang dipilih.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
            else if (isWide)
              GlassContainer(
                tier: GlassTier.level1,
                padding: const EdgeInsets.all(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    columns: const [
                      DataColumn(label: Text('Kode Pesanan')),
                      DataColumn(label: Text('Waktu (WIB)')),
                      DataColumn(label: Text('Pemesan')),
                      DataColumn(label: Text('Kasir')),
                      DataColumn(label: Text('Metode')),
                      DataColumn(label: Text('Ref Xendit')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Total'), numeric: true),
                    ],
                    rows: _orders.map((o) {
                      return DataRow(
                        cells: [
                          DataCell(Text(o.orderCode,
                              style: AppFormatters.tabular(
                                  theme.textTheme.labelLarge))),
                          DataCell(Text(AppFormatters.dateTimeWib(o.createdAt),
                              style: AppFormatters.tabular(
                                  theme.textTheme.bodySmall))),
                          DataCell(Text(o.customerName ?? '-')),
                          DataCell(Text(o.cashierName ?? '-')),
                          DataCell(Text(o.paymentMethodCode)),
                          DataCell(Text(o.payment?.gatewayReference ?? '-',
                              style: AppFormatters.tabular(
                                  theme.textTheme.bodySmall))),
                          DataCell(
                              GlassStatusBadge(status: o.status, compact: true)),
                          DataCell(Text(
                            AppFormatters.rupiah(o.totalAmount),
                            style: AppFormatters.tabular(
                              theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.tertiaryLight,
                              ),
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              Column(
                children: _orders.map((o) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassContainer(
                      tier: GlassTier.level1,
                      enableBlur: false,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(o.orderCode,
                                    style: AppFormatters.tabular(
                                        theme.textTheme.titleMedium)),
                              ),
                              GlassStatusBadge(status: o.status, compact: true),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${AppFormatters.dateTimeWib(o.createdAt)} • Kasir: ${o.cashierName ?? '-'}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${o.paymentMethodCode} • ${o.payment?.gatewayReference ?? '-'}',
                                style: AppFormatters.tabular(
                                    theme.textTheme.bodySmall),
                              ),
                              Text(
                                AppFormatters.rupiah(o.totalAmount),
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
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final double? progress;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      tier: GlassTier.level1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFormatters.tabular(
              theme.textTheme.headlineSmall?.copyWith(color: accent),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (progress != null) ...[
                GlassProgressBar(
                  value: progress!,
                  variant: GlassProgressVariant.tertiary,
                ),
                const SizedBox(height: 6),
              ],
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
