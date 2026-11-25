import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/order_model.dart';
import 'formatters.dart';
import 'report_exporter_stub.dart'
    if (dart.library.html) 'report_exporter_web.dart'
    if (dart.library.js_interop) 'report_exporter_web.dart'
    if (dart.library.io) 'report_exporter_io.dart' as platform_saver;

enum ReportFormat { xlsx, csv, pdf }

class ReportSummary {
  final int totalRevenuePaid;
  final int paidCount;
  final int rejectedCount;
  final int pendingOrOtherCount;
  final Map<String, int> revenueByMethod;
  final Map<String, int> countByMethod;
  final Map<String, int> revenueByCashier;

  const ReportSummary({
    required this.totalRevenuePaid,
    required this.paidCount,
    required this.rejectedCount,
    required this.pendingOrOtherCount,
    required this.revenueByMethod,
    required this.countByMethod,
    required this.revenueByCashier,
  });

  factory ReportSummary.fromOrders(List<OrderModel> orders) {
    int totalPaid = 0;
    int paidCount = 0;
    int rejectedCount = 0;
    int otherCount = 0;
    final byMethodRev = <String, int>{};
    final byMethodCount = <String, int>{};
    final byCashierRev = <String, int>{};

    for (final order in orders) {
      if (order.status == OrderStatus.paidAccepted) {
        totalPaid += order.totalAmount;
        paidCount++;
        final method = order.paymentMethodCode;
        byMethodRev[method] = (byMethodRev[method] ?? 0) + order.totalAmount;
        byMethodCount[method] = (byMethodCount[method] ?? 0) + 1;
        final cashier = order.cashierName ?? 'Tanpa Kasir';
        byCashierRev[cashier] = (byCashierRev[cashier] ?? 0) + order.totalAmount;
      } else if (order.status == OrderStatus.rejected) {
        rejectedCount++;
      } else {
        otherCount++;
      }
    }

    return ReportSummary(
      totalRevenuePaid: totalPaid,
      paidCount: paidCount,
      rejectedCount: rejectedCount,
      pendingOrOtherCount: otherCount,
      revenueByMethod: byMethodRev,
      countByMethod: byMethodCount,
      revenueByCashier: byCashierRev,
    );
  }
}

/// Cross-platform Uint8List Daily Report Exporter (.xlsx, .csv, .pdf)
/// Totals strictly match PAID_ACCEPTED aggregation in PostgreSQL (WIB).
class ReportExporter {
  static Future<String> exportReport({
    required List<OrderModel> orders,
    required DateTime startDate,
    required DateTime endDate,
    required ReportFormat format,
  }) async {
    final summary = ReportSummary.fromOrders(orders);
    final dateTag = AppFormatters.isoDate(startDate) == AppFormatters.isoDate(endDate)
        ? AppFormatters.isoDate(startDate)
        : '${AppFormatters.isoDate(startDate)}_sd_${AppFormatters.isoDate(endDate)}';

    switch (format) {
      case ReportFormat.xlsx:
        final bytes = buildExcelBytes(
          orders: orders,
          summary: summary,
          startDate: startDate,
          endDate: endDate,
        );
        return platform_saver.saveReportFile(
          bytes: bytes,
          fileName: 'laporan_harian_$dateTag.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      case ReportFormat.csv:
        final bytes = buildCsvBytes(
          orders: orders,
          summary: summary,
          startDate: startDate,
          endDate: endDate,
        );
        return platform_saver.saveReportFile(
          bytes: bytes,
          fileName: 'laporan_harian_$dateTag.csv',
          mimeType: 'text/csv;charset=utf-8',
        );
      case ReportFormat.pdf:
        final bytes = await buildPdfBytes(
          orders: orders,
          summary: summary,
          startDate: startDate,
          endDate: endDate,
        );
        return platform_saver.saveReportFile(
          bytes: bytes,
          fileName: 'laporan_harian_$dateTag.pdf',
          mimeType: 'application/pdf',
        );
    }
  }

  static Uint8List buildExcelBytes({
    required List<OrderModel> orders,
    required ReportSummary summary,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Harian'];
    excel.delete('Sheet1');

    sheet.appendRow([TextCellValue('LAPORAN TRANSAKSI HARIAN (WIB)')]);
    sheet.appendRow([
      TextCellValue('Periode'),
      TextCellValue(
          '${AppFormatters.dateReadable(startDate)} - ${AppFormatters.dateReadable(endDate)}'),
    ]);
    sheet.appendRow([
      TextCellValue('Total Omzet (PAID_ACCEPTED)'),
      IntCellValue(summary.totalRevenuePaid),
    ]);
    sheet.appendRow([
      TextCellValue('Transaksi Berhasil'),
      IntCellValue(summary.paidCount),
    ]);
    sheet.appendRow([
      TextCellValue('Transaksi Ditolak'),
      IntCellValue(summary.rejectedCount),
    ]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([TextCellValue('RINGKASAN PER METODE PEMBAYARAN (PAID)')]);
    sheet.appendRow([
      TextCellValue('Metode'),
      TextCellValue('Jumlah Transaksi'),
      TextCellValue('Total Nilai (Rp)'),
    ]);
    summary.revenueByMethod.forEach((method, total) {
      sheet.appendRow([
        TextCellValue(method),
        IntCellValue(summary.countByMethod[method] ?? 0),
        IntCellValue(total),
      ]);
    });
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([TextCellValue('RINCIAN TRANSAKSI PER KASIR')]);
    sheet.appendRow([
      TextCellValue('Nomor Pesanan'),
      TextCellValue('Waktu (WIB)'),
      TextCellValue('Pemesan'),
      TextCellValue('Kasir'),
      TextCellValue('Metode Bayar'),
      TextCellValue('Referensi Xendit'),
      TextCellValue('Status'),
      TextCellValue('Total (Rp)'),
      TextCellValue('Alasan Penolakan'),
    ]);

    for (final o in orders) {
      sheet.appendRow([
        TextCellValue(o.orderCode),
        TextCellValue(AppFormatters.dateTimeWib(o.createdAt)),
        TextCellValue(o.customerName ?? '-'),
        TextCellValue(o.cashierName ?? '-'),
        TextCellValue(o.paymentMethodCode),
        TextCellValue(o.payment?.gatewayReference ?? '-'),
        TextCellValue(o.status.dbValue),
        IntCellValue(o.totalAmount),
        TextCellValue(o.rejectionReason ?? '-'),
      ]);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? <int>[]);
  }

  static Uint8List buildCsvBytes({
    required List<OrderModel> orders,
    required ReportSummary summary,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final buf = StringBuffer();
    buf.writeln('LAPORAN TRANSAKSI HARIAN (WIB)');
    buf.writeln(
        'Periode,${esc('${AppFormatters.dateReadable(startDate)} - ${AppFormatters.dateReadable(endDate)}')}');
    buf.writeln('Total Omzet (PAID_ACCEPTED),${summary.totalRevenuePaid}');
    buf.writeln('Transaksi Berhasil,${summary.paidCount}');
    buf.writeln('Transaksi Ditolak,${summary.rejectedCount}');
    buf.writeln('');
    buf.writeln('RINGKASAN PER METODE PEMBAYARAN');
    buf.writeln('Metode,Jumlah,Total (Rp)');
    summary.revenueByMethod.forEach((method, total) {
      buf.writeln('${esc(method)},${summary.countByMethod[method] ?? 0},$total');
    });
    buf.writeln('');
    buf.writeln(
        'Nomor Pesanan,Waktu (WIB),Pemesan,Kasir,Metode Bayar,Referensi Xendit,Status,Total (Rp),Alasan Penolakan');
    for (final o in orders) {
      buf.writeln([
        esc(o.orderCode),
        esc(AppFormatters.dateTimeWib(o.createdAt)),
        esc(o.customerName ?? '-'),
        esc(o.cashierName ?? '-'),
        esc(o.paymentMethodCode),
        esc(o.payment?.gatewayReference ?? '-'),
        esc(o.status.dbValue),
        o.totalAmount.toString(),
        esc(o.rejectionReason ?? '-'),
      ].join(','));
    }
    return Uint8List.fromList(utf8.encode(buf.toString()));
  }

  static Future<Uint8List> buildPdfBytes({
    required List<OrderModel> orders,
    required ReportSummary summary,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final doc = pw.Document();
    final periodText =
        '${AppFormatters.dateReadable(startDate)} - ${AppFormatters.dateReadable(endDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'LAPORAN HARIAN TRANSAKSI POS & QRIS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Periode (WIB): $periodText',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _pdfMetric('Total Omzet (Lunas)',
                  AppFormatters.rupiah(summary.totalRevenuePaid)),
              pw.SizedBox(width: 12),
              _pdfMetric('Berhasil (PAID)', '${summary.paidCount} transaksi'),
              pw.SizedBox(width: 12),
              _pdfMetric('Ditolak', '${summary.rejectedCount} transaksi'),
              pw.SizedBox(width: 12),
              _pdfMetric('Total Baris', '${orders.length} pesanan'),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Pemecahan per Metode Pembayaran (PAID_ACCEPTED)',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle:
                pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Metode Pembayaran', 'Jumlah Transaksi', 'Total Nilai'],
            data: summary.revenueByMethod.entries
                .map((e) => [
                      e.key,
                      '${summary.countByMethod[e.key] ?? 0}',
                      AppFormatters.rupiah(e.value),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Rincian Transaksi per Kasir',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: [
              'Kode Pesanan',
              'Waktu WIB',
              'Pemesan',
              'Kasir',
              'Metode',
              'Ref Xendit',
              'Status',
              'Total',
            ],
            data: orders
                .map((o) => [
                      o.orderCode,
                      AppFormatters.dateTimeWib(o.createdAt),
                      o.customerName ?? '-',
                      o.cashierName ?? '-',
                      o.paymentMethodCode,
                      o.payment?.gatewayReference ?? '-',
                      o.status.dbValue,
                      AppFormatters.rupiah(o.totalAmount),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfMetric(String title, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
