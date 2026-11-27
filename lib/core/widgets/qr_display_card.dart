import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';
import 'glass_progress_bar.dart';

/// QR Presentation Card with PURE WHITE (#FFFFFF) quiet zone >= 16px
/// and #000000 QR modules on crisp tactile paper card surface.
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
    final isUrgent = remainingDuration != null && remainingDuration!.inSeconds <= 60;

    return GlassContainer(
      tier: GlassTier.level1,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      orderCode,
                      style: AppFormatters.tabular(
                        theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 18),
          // CRITICAL: Pure White (#FFFFFF) Quiet Zone >= 16px, Black (#000000) QR Modules
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F2933).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
            GlassProgressBar(
              value: progress,
              variant: GlassProgressVariant.tertiary,
              height: 6,
            ),
            const SizedBox(height: 8),
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
                    theme.textTheme.labelMedium?.copyWith(
                      color: isUrgent
                          ? AppColors.semanticError
                          : AppColors.accentTerracotta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.slateHeader,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}
