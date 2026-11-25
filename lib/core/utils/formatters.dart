import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _idrFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Formats integer Rupiah value, e.g., 25000 -> "Rp 25.000"
  static String rupiah(num amount) => _idrFormatter.format(amount);

  /// Mandatory tabular figures style for all prices, totals, and countdown timers
  static TextStyle tabular(TextStyle? base) {
    return (base ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Convert any DateTime to operational store timezone Asia/Jakarta (WIB, UTC+7)
  static DateTime toWib(DateTime dt) => dt.toUtc().add(const Duration(hours: 7));

  /// Today's date in WIB (year, month, day)
  static DateTime todayWib() {
    final nowWib = toWib(DateTime.now());
    return DateTime(nowWib.year, nowWib.month, nowWib.day);
  }

  /// Format Date as YYYY-MM-DD (for PostgreSQL date RPC params & filenames)
  static String isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Format DateTime in WIB: "25 Nov 2026, 14:30 WIB"
  static String dateTimeWib(DateTime dt) {
    final wib = toWib(dt);
    final formatted = DateFormat('dd MMM yyyy, HH:mm').format(wib);
    return '$formatted WIB';
  }

  /// Format Time in WIB: "14:30 WIB"
  static String timeWib(DateTime dt) {
    final wib = toWib(dt);
    return '${DateFormat('HH:mm').format(wib)} WIB';
  }

  /// Format Date readable: "25 Nov 2026"
  static String dateReadable(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format Duration countdown as MM:SS
  static String countdown(Duration remaining) {
    if (remaining.isNegative) return '00:00';
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = remaining.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
