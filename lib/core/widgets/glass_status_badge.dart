import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../theme/app_colors.dart';

/// Semantic Status Badge implementing Terracotta & Slate POS two-part matrix.
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
        return AppColors.statusPendingText; // #B45309
      case OrderStatus.paymentProcessing:
        return AppColors.statusProcessingText; // #2B547E
      case OrderStatus.paidAccepted:
        return AppColors.semanticSuccess; // #16A34A
      case OrderStatus.rejected:
        return AppColors.semanticError; // #DC2626
      case OrderStatus.expired:
        return AppColors.textSecondary; // #64748B
    }
  }

  Color get _background {
    switch (status) {
      case OrderStatus.pendingVerification:
        return AppColors.semanticWarningSoft;
      case OrderStatus.paymentProcessing:
        return AppColors.statusProcessingSoft;
      case OrderStatus.paidAccepted:
        return AppColors.semanticSuccessSoft;
      case OrderStatus.rejected:
        return AppColors.semanticErrorSoft;
      case OrderStatus.expired:
        return AppColors.statusExpiredBg;
    }
  }

  Color get _borderColor {
    switch (status) {
      case OrderStatus.pendingVerification:
        return AppColors.statusPendingBorder;
      case OrderStatus.paymentProcessing:
        return AppColors.statusProcessingBorder;
      case OrderStatus.paidAccepted:
        return AppColors.statusPaidBorder;
      case OrderStatus.rejected:
        return AppColors.statusErrorBorder;
      case OrderStatus.expired:
        return AppColors.borderDefault;
    }
  }

  IconData get _icon {
    switch (status) {
      case OrderStatus.pendingVerification:
        return Icons.hourglass_top_rounded;
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
        horizontal: compact ? 8 : 11,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12 : 14, color: _foreground),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _foreground,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
