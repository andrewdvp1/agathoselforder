import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../theme/app_colors.dart';

/// Mandatory Reusable Widget #3: GlassStatusBadge
/// Maps PostgreSQL `order_status` enum directly to semantic colors & icons
/// defined in Design System Section 2.3.
class GlassStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool compact;

  const GlassStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color get _foreground {
    switch (status) {
      case OrderStatus.pendingVerification:
        return AppColors.tertiaryLight; // #FBBF24
      case OrderStatus.paymentProcessing:
        return AppColors.primaryLight; // #818CF8
      case OrderStatus.paidAccepted:
        return AppColors.secondaryLight; // #34D399
      case OrderStatus.rejected:
        return AppColors.errorLight; // #F87171
      case OrderStatus.expired:
        return AppColors.textSecondary; // #94A3B8
    }
  }

  Color get _background {
    switch (status) {
      case OrderStatus.pendingVerification:
        return AppColors.statusPendingBg;
      case OrderStatus.paymentProcessing:
        return AppColors.statusProcessingBg;
      case OrderStatus.paidAccepted:
        return AppColors.statusPaidBg;
      case OrderStatus.rejected:
        return AppColors.statusRejectedBg;
      case OrderStatus.expired:
        return AppColors.statusExpiredBg;
    }
  }

  IconData get _icon {
    switch (status) {
      case OrderStatus.pendingVerification:
        return Icons.schedule_rounded;
      case OrderStatus.paymentProcessing:
        return Icons.qr_code_2_rounded;
      case OrderStatus.paidAccepted:
        return Icons.check_circle_rounded;
      case OrderStatus.rejected:
        return Icons.cancel_rounded;
      case OrderStatus.expired:
        return Icons.timer_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _foreground.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 13 : 15, color: _foreground),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _foreground,
                  fontSize: compact ? 11 : 12,
                ),
          ),
        ],
      ),
    );
  }
}
