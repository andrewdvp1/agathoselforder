import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_exporter.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_status_badge.dart';
import '../../core/widgets/pos_header.dart';
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
  int _presetIndex = 0; // 0: Hari Ini, 1: 7 Hari, 2: Bulan Ini, -1: Custom
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

  Future<void> _applyPreset(int idx) async {
    final today = AppFormatters.todayWib();
    setState(() {
      _presetIndex = idx;
      if (idx == 0) {
        _startDate = today;
        _endDate = today;
      } else if (idx == 1) {
        _startDate = today.subtract(const Duration(days: 6));
        _endDate = today;
      } else {
        _startDate = DateTime(today.year, today.month, 1);
        _endDate = today;
      }
    });
    await _loadOrders();
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.slateHeader,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
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
        _presetIndex = -1;
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

  Widget _buildExportButton() {
    return PopupMenuButton<ReportFormat>(
      enabled: !_exporting,
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      onSelected: _export,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: ReportFormat.xlsx,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.table_chart_rounded,
              color: AppColors.semanticSuccess,
            ),
            title: Text('Unduh Excel (.xlsx)'),
          ),
        ),
        PopupMenuItem(
          value: ReportFormat.csv,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.description_outlined,
              color: AppColors.slateHeader,
            ),
            title: Text('Unduh CSV (.csv)'),
          ),
        ),
        PopupMenuItem(
          value: ReportFormat.pdf,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.semanticError,
            ),
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
    );
  }

  Widget _buildPresetPills() {
    const labels = ['Hari Ini', '7 Hari', 'Bulan Ini'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfacePillInactive,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final active = _presetIndex == i;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _applyPreset(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      active ? AppColors.accentTerracotta : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labels[i],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ReportSummary.fromOrders(_orders);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWide = screenWidth > 860;
    final isSingleDay =
        AppFormatters.isoDate(_startDate) == AppFormatters.isoDate(_endDate);
    final dateLabel = isSingleDay
        ? AppFormatters.dateReadable(_startDate)
        : '${AppFormatters.dateReadable(_startDate)} – ${AppFormatters.dateReadable(_endDate)}';

    final qrisTotal = summary.revenueByMethod['QRIS'] ?? 0;
    final qrisRatio = summary.totalRevenuePaid == 0
        ? 0.0
        : qrisTotal / summary.totalRevenuePaid;

    final bodyContent = Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 24,
        isMobile ? 16 : 22,
        isMobile ? 20 : 24,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'RINGKASAN OPERASIONAL',
                            style: TextStyle(
                              color: AppColors.accentTerracotta,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.semanticSuccessSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: AppColors.semanticSuccess,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'WIB (Asia/Jakarta)',
                                style: TextStyle(
                                  color: AppColors.semanticSuccess,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dashboard & Laporan Harian',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Periode: $dateLabel • Agregasi transaksi seluruh kasir',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildPresetPills(),
                    _buildExportButton(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
          ] else ...[
            Center(child: _buildPresetPills()),
            const SizedBox(height: 14),
          ],

          // Filter Panel
          GlassContainer(
            tier: GlassTier.level1,
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GlassSecondaryButton(
                  label: 'Tanggal: $dateLabel',
                  icon: Icons.calendar_today_rounded,
                  onPressed: _pickDateRange,
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 195,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedCashierId,
                    dropdownColor: AppColors.surfaceCard,
                    decoration: const InputDecoration(
                      labelText: 'Kasir',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                  width: isMobile ? double.infinity : 185,
                  child: DropdownButtonFormField<OrderStatus?>(
                    initialValue: _selectedStatus,
                    dropdownColor: AppColors.surfaceCard,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                  width: isMobile ? double.infinity : 185,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedPaymentMethod,
                    dropdownColor: AppColors.surfaceCard,
                    decoration: const InputDecoration(
                      labelText: 'Metode Bayar',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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

          // Metric Summary Cards (4 cols desktop, 2 cols tablet/mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 960
                  ? 4
                  : (constraints.maxWidth > 320 ? 2 : 1);

              final metricCards = [
                _MetricCard(
                  title: 'Total Omzet (Lunas)',
                  value: AppFormatters.rupiah(summary.totalRevenuePaid),
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: AppColors.accentSoft,
                  iconFg: AppColors.accentTerracotta,
                  pillText: '${summary.paidCount} Transaksi Lunas',
                  pillBg: AppColors.semanticSuccessSoft,
                  pillFg: AppColors.semanticSuccess,
                ),
                _MetricCard(
                  title: 'Transaksi Selesai',
                  value: '${summary.paidCount} Pesanan',
                  icon: Icons.receipt_long_rounded,
                  iconBg: AppColors.statusProcessingSoft,
                  iconFg: AppColors.statusProcessingText,
                  pillText: 'Dari ${_orders.length} total',
                  pillBg: AppColors.surfacePillInactive,
                  pillFg: AppColors.textSecondary,
                ),
                _MetricCard(
                  title: 'QRIS Xendit (Lunas)',
                  value: AppFormatters.rupiah(qrisTotal),
                  icon: Icons.qr_code_2_rounded,
                  iconBg: AppColors.accentSoft,
                  iconFg: AppColors.accentTerracotta,
                  pillText:
                      '${(qrisRatio * 100).toStringAsFixed(0)}% dari total omzet',
                  pillBg: AppColors.statusProcessingSoft,
                  pillFg: AppColors.statusProcessingText,
                ),
                _MetricCard(
                  title: 'Ditolak / Batal',
                  value: '${summary.rejectedCount}',
                  icon: Icons.cancel_outlined,
                  iconBg: AppColors.semanticErrorSoft,
                  iconFg: AppColors.semanticError,
                  pillText: 'Pending/Exp: ${summary.pendingOrOtherCount}',
                  pillBg: AppColors.semanticWarningSoft,
                  pillFg: AppColors.statusPendingText,
                ),
              ];

              return GridView.builder(
                itemCount: metricCards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 132,
                ),
                itemBuilder: (_, i) => metricCards[i],
              );
            },
          ),

          const SizedBox(height: 16),

          // Real-Data Visual Analytics Row (Trend Bar Chart + Payment Composition)
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth > 760;
              final trendCard = _SalesTrendCard(
                orders: _orders,
                singleDay: isSingleDay,
              );
              final compositionCard = _PaymentCompositionCard(summary: summary);

              if (twoCols) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: trendCard),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: compositionCard),
                  ],
                );
              }
              return Column(
                children: [
                  trendCard,
                  const SizedBox(height: 14),
                  compositionCard,
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Transactions Ledger Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Histori Transaksi',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_orders.length} Data',
                style: AppFormatters.tabular(
                  theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentTerracotta,
                ),
              ),
            )
          else if (_error != null)
            GlassContainer(
              tier: GlassTier.level1,
              padding: const EdgeInsets.all(20),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.semanticError,
                ),
              ),
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
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(AppColors.surfaceRowHover),
                  headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  dataRowMinHeight: 54,
                  dataRowMaxHeight: 62,
                  dividerThickness: 0.7,
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
                        DataCell(
                          Text(
                            o.orderCode,
                            style: AppFormatters.tabular(
                              theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.dateTimeWib(o.createdAt),
                            style: AppFormatters.tabular(
                              theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            o.customerName ?? '-',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            o.cashierName ?? '-',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusProcessingSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              o.paymentMethodCode,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.statusProcessingText,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            o.payment?.gatewayReference ?? '-',
                            style: AppFormatters.tabular(
                              theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                        DataCell(
                          GlassStatusBadge(status: o.status, compact: true),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.rupiah(o.totalAmount),
                            style: AppFormatters.tabular(
                              theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            )
          else
            Column(
              children: _orders.map((o) {
                final itemsText = o.items
                    .map((i) => '${i.quantity}x ${i.menuNameSnapshot}')
                    .join(', ');
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ctaDark,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                o.orderCode,
                                style: AppFormatters.tabular(
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppFormatters.timeWib(o.createdAt),
                                style: AppFormatters.tabular(
                                  theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            GlassStatusBadge(status: o.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              o.customerName ?? 'Pengunjung',
                              style: theme.textTheme.labelLarge,
                            ),
                            Text(
                              'Kasir: ${o.cashierName ?? '-'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (itemsText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.bgCanvas,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              itemsText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusProcessingSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                o.paymentMethodCode,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.statusProcessingText,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              AppFormatters.rupiah(o.totalAmount),
                              style: AppFormatters.tabular(
                                theme.textTheme.titleMedium?.copyWith(
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
                );
              }).toList(),
            ),

          if (isMobile) ...[
            const SizedBox(height: 16),
            _buildExportButton(),
          ],
        ],
      ),
    );

    if (isMobile) {
      return RefreshIndicator(
        color: AppColors.accentTerracotta,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: _loadOrders,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PosSlateHeader(
                eyebrow: 'ADMIN PORTAL • WIB',
                title: 'Ringkasan & Laporan',
                subtitle: dateLabel,
                trailing: PosHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Muat ulang',
                  onPressed: _loadOrders,
                ),
              ),
            ),
            SliverToBoxAdapter(child: bodyContent),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accentTerracotta,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: bodyContent,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String pillText;
  final Color pillBg;
  final Color pillFg;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.pillText,
    required this.pillBg,
    required this.pillFg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      tier: GlassTier.level1,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconFg),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFormatters.tabular(
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pillText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pillFg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  final List<OrderModel> orders;
  final bool singleDay;

  const _SalesTrendCard({
    required this.orders,
    required this.singleDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidOrders =
        orders.where((o) => o.status == OrderStatus.paidAccepted).toList();

    // Aggregate real paid revenue by hour (singleDay) or date (multi-day)
    final Map<String, int> buckets = {};
    for (final o in paidOrders) {
      final wib = AppFormatters.toWib(o.createdAt);
      final key = singleDay
          ? '${wib.hour.toString().padLeft(2, '0')}:00'
          : '${wib.day.toString().padLeft(2, '0')}/${wib.month.toString().padLeft(2, '0')}';
      buckets[key] = (buckets[key] ?? 0) + o.totalAmount;
    }

    final sortedKeys = buckets.keys.toList()..sort();
    final displayKeys =
        sortedKeys.length > 10 ? sortedKeys.sublist(sortedKeys.length - 10) : sortedKeys;
    final maxVal = displayKeys.isEmpty
        ? 0
        : displayKeys
            .map((k) => buckets[k] ?? 0)
            .reduce((a, b) => a > b ? a : b);

    return GlassContainer(
      tier: GlassTier.level1,
      padding: const EdgeInsets.all(18),
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
                      singleDay
                          ? 'Tren Penjualan Per Jam (WIB)'
                          : 'Tren Penjualan Harian (WIB)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Berdasarkan transaksi lunas (${paidOrders.length} pesanan)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (maxVal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Peak: ${AppFormatters.rupiah(maxVal)}',
                    style: AppFormatters.tabular(
                      const TextStyle(
                        color: AppColors.accentTerracotta,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (displayKeys.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Belum ada transaksi lunas untuk ditampilkan pada grafik.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: displayKeys.map((k) {
                  final val = buckets[k] ?? 0;
                  final ratio = maxVal == 0 ? 0.0 : (val / maxVal);
                  final isPeak = val == maxVal && maxVal > 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: '$k: ${AppFormatters.rupiah(val)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: (0.14 + ratio * 0.86).clamp(0.14, 1.0),
                                  widthFactor: 0.72,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isPeak
                                          ? AppColors.accentTerracotta
                                          : AppColors.slateHeader,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              k,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFormatters.tabular(
                                theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: isPeak
                                      ? AppColors.accentTerracotta
                                      : AppColors.textSecondary,
                                  fontWeight: isPeak
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentCompositionCard extends StatelessWidget {
  final ReportSummary summary;

  const _PaymentCompositionCard({required this.summary});

  Color _colorForMethod(String code) {
    if (code == 'QRIS') return AppColors.accentTerracotta;
    if (code == 'CASH') return AppColors.textMuted;
    if (code.startsWith('VA_')) return AppColors.semanticSuccess;
    return AppColors.slateHeader;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = summary.revenueByMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassContainer(
      tier: GlassTier.level1,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Komposisi Metode Pembayaran',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusProcessingSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Xendit',
                  style: TextStyle(
                    color: AppColors.statusProcessingText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Distribusi settlement transaksi lunas',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Container(
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Belum ada transaksi lunas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else ...[
            // Multi-segment stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: entries.map((entry) {
                    final flex = entry.value <= 0 ? 1 : entry.value;
                    return Expanded(
                      flex: flex,
                      child: Container(
                        color: _colorForMethod(entry.key),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...entries.map((entry) {
              final ratio = summary.totalRevenuePaid == 0
                  ? 0.0
                  : entry.value / summary.totalRevenuePaid;
              final count = summary.countByMethod[entry.key] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colorForMethod(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$count transaksi',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: AppFormatters.tabular(
                            theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          AppFormatters.rupiah(entry.value),
                          style: AppFormatters.tabular(
                            theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
