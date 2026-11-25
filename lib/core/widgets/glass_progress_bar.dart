import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GlassProgressVariant { primary, secondary, tertiary }

class GlassProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final GlassProgressVariant variant;
  final double height;

  const GlassProgressBar({
    super.key,
    required this.value,
    this.variant = GlassProgressVariant.primary,
    this.height = 6,
  });

  Color get _fillColor {
    switch (variant) {
      case GlassProgressVariant.primary:
        return AppColors.primaryTonalAlt;
      case GlassProgressVariant.secondary:
        return AppColors.secondaryLight;
      case GlassProgressVariant.tertiary:
        return AppColors.tertiaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.white.withValues(alpha: 0.10),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: _fillColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
