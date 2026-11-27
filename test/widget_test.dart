import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_order_apps/core/config/supabase_config.dart';
import 'package:self_order_apps/core/theme/app_colors.dart';
import 'package:self_order_apps/core/utils/formatters.dart';
import 'package:self_order_apps/core/utils/report_exporter.dart';
import 'package:self_order_apps/core/widgets/glass_container.dart';
import 'package:self_order_apps/core/widgets/glass_scaffold.dart';
import 'package:self_order_apps/core/widgets/glass_status_badge.dart';
import 'package:self_order_apps/core/widgets/qr_display_card.dart';
import 'package:self_order_apps/models/order_model.dart';

void main() {
  test('AppFormatters formats Rupiah, WIB timezone, and countdown accurately', () {
    expect(AppFormatters.rupiah(25000), 'Rp 25.000');
    expect(AppFormatters.rupiah(1250000), 'Rp 1.250.000');
    expect(AppFormatters.countdown(const Duration(minutes: 14, seconds: 5)), '14:05');
    expect(AppFormatters.countdown(const Duration(seconds: -10)), '00:00');

    // 2026-11-25 17:30 UTC == 2026-11-26 00:30 WIB (crosses midnight correctly!)
    final utcLate = DateTime.utc(2026, 11, 25, 17, 30);
    final wib = AppFormatters.toWib(utcLate);
    expect(wib.day, 26);
    expect(wib.hour, 0);
    expect(wib.minute, 30);
  });

  test('ReportSummary aggregates ONLY PAID_ACCEPTED orders and exports xlsx/csv/pdf bytes', () async {
    final sampleOrders = [
      OrderModel(
        id: 'o1',
        orderCode: 'ORD-001',
        qrToken: 'tok-1',
        userId: 'u1',
        customerName: 'Andi',
        cashierId: 'c1',
        cashierName: 'Kasir Budi',
        totalAmount: 59000,
        status: OrderStatus.paidAccepted,
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        createdAt: DateTime.utc(2026, 11, 25, 5, 0),
        payment: const PaymentModel(
          id: 'p1',
          orderId: 'o1',
          paymentMethod: 'QRIS',
          gatewayProvider: 'xendit',
          gatewayReference: 'qr_test_001',
          amount: 59000,
          status: PaymentStatus.paid,
        ),
      ),
      OrderModel(
        id: 'o2',
        orderCode: 'ORD-002',
        qrToken: 'tok-2',
        userId: 'u2',
        customerName: 'Rina',
        cashierId: 'c2',
        cashierName: 'Kasir Siti',
        totalAmount: 26000,
        status: OrderStatus.rejected,
        rejectionReason: 'Stok habis',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        createdAt: DateTime.utc(2026, 11, 25, 6, 0),
        payment: const PaymentModel(
          id: 'p2',
          orderId: 'o2',
          paymentMethod: 'QRIS',
          gatewayProvider: 'xendit',
          amount: 26000,
          status: PaymentStatus.failed,
        ),
      ),
    ];

    final summary = ReportSummary.fromOrders(sampleOrders);
    expect(summary.totalRevenuePaid, 59000);
    expect(summary.paidCount, 1);
    expect(summary.rejectedCount, 1);
    expect(summary.revenueByMethod['QRIS'], 59000);

    final day = DateTime(2026, 11, 25);
    final xlsxBytes = ReportExporter.buildExcelBytes(
      orders: sampleOrders,
      summary: summary,
      startDate: day,
      endDate: day,
    );
    final csvBytes = ReportExporter.buildCsvBytes(
      orders: sampleOrders,
      summary: summary,
      startDate: day,
      endDate: day,
    );
    final pdfBytes = await ReportExporter.buildPdfBytes(
      orders: sampleOrders,
      summary: summary,
      startDate: day,
      endDate: day,
    );

    expect(xlsxBytes.isNotEmpty, isTrue);
    expect(csvBytes.isNotEmpty, isTrue);
    expect(pdfBytes.isNotEmpty, isTrue);
  });

  testWidgets('Core Glassmorphic widgets & pure-white QR quiet zone render cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: GlassScaffold(
          showTertiaryOrb: true,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                GlassContainer(
                  tier: GlassTier.level1,
                  enableBlur: false,
                  padding: EdgeInsets.all(12),
                  child: GlassStatusBadge(status: OrderStatus.paidAccepted),
                ),
                SizedBox(height: 12),
                QrDisplayCard(
                  title: 'QR Code Pesanan',
                  subtitle: 'Tunjukkan ke kasir',
                  qrData: '55555555-5555-4555-8555-555555555505',
                  orderCode: 'ORD-SEED-005',
                  totalAmount: 48000,
                  remainingDuration: Duration(minutes: 18, seconds: 42),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    expect(find.text('ORD-SEED-005'), findsOneWidget);
    expect(find.text('Rp 48.000'), findsOneWidget);
    expect(find.text('18:42'), findsOneWidget);

    // Ensure pure white quiet zone container (#FFFFFF) exists for QR legibility
    final whiteContainers = tester.widgetList<Container>(find.byType(Container)).where((c) {
      final dec = c.decoration;
      return dec is BoxDecoration && dec.color == const Color(0xFFFFFFFF);
    });
    expect(whiteContainers.isNotEmpty, isTrue);
    expect(AppColors.bgCanvas, const Color(0xFFF7F8FA));
  });

  test('SupabaseConfig validates Supabase Cloud HTTPS configuration cleanly', () {
    expect(SupabaseConfig.menuImagesBucket, 'menu-images');
    expect(SupabaseConfig.paymentEnvironment.isNotEmpty, isTrue);
    // Rejects localhost; accepts real Supabase Cloud HTTPS URL + key
    if (SupabaseConfig.url.contains('YOUR_PROJECT_REF')) {
      expect(SupabaseConfig.isConfigured, isFalse);
    } else {
      expect(SupabaseConfig.isCloudUrl, isTrue);
      expect(SupabaseConfig.hasValidAnonKey, isTrue);
      expect(SupabaseConfig.isConfigured, isTrue);
    }
  });
}
