import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';
import 'glass_progress_bar.dart';

/// Mandatory Reusable Widget #4: QrDisplayCard
/// Wraps QrImageView inside a PURE WHITE (#FFFFFF) solid container with >=16px
/// quiet zone and #000000 QR modules to guarantee 100% scan reliability on dark UI.
class QrDisplayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String qrData;
  final String orderCode;
  final int totalAmount;
  final Duration? remainingDuration;
  final Duration totalDuration;
  final Widget? badge;
  final Widget? footer;
  final double qrSize;

  const QrDisplayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.qrData,
    required this.orderCode,
    required this.totalAmount,
    this.remainingDuration,
    this.totalDuration = const Duration(minutes: 20),
    this.badge,
    this.footer,
    this.qrSize = 220,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = remainingDuration != null && totalDuration.inSeconds > 0
        ? (remainingDuration!.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return GlassContainer(
      tier: GlassTier.level2,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      orderCode,
                      style: AppFormatters.tabular(
                        theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryTonal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(subtitle, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 18),
          // CRITICAL: Pure White (#FFFFFF) Quiet Zone >= 16px, Black (#000000) QR Modules
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: const Color(0xFFFFFFFF),
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF000000),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF000000),
              ),
              gapless: true,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Total Pembayaran',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.rupiah(totalAmount),
            style: AppFormatters.tabular(
              theme.textTheme.displaySmall?.copyWith(
                fontSize: 28,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (remainingDuration != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Berlaku selama',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppFormatters.countdown(remainingDuration!),
                  style: AppFormatters.tabular(
                    theme.textTheme.labelLarge?.copyWith(
                      color: remainingDuration!.inSeconds <= 60
                          ? AppColors.errorLight
                          : AppColors.tertiaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlassProgressBar(
              value: progress,
              variant: GlassProgressVariant.tertiary,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}
