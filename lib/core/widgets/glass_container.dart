import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GlassTier {
  level1, // Pure white card with subtle hairline border & soft ambient drop
  level2, // Floating / straddling module with elevated ambient drop
  level3, // Modal / overlay surface
}

/// Tactile Paper Sheet Card Container implementing Terracotta & Slate POS elevation tiers.
class GlassContainer extends StatefulWidget {
  final Widget child;
  final GlassTier tier;
  final bool enableBlur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final BoxConstraints? constraints;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.tier = GlassTier.level1,
    this.enableBlur = true,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
    this.constraints,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _hovered = false;

  Color get _defaultBorderColor {
    switch (widget.tier) {
      case GlassTier.level1:
        return AppColors.borderSubtle;
      case GlassTier.level2:
        return AppColors.borderDefault;
      case GlassTier.level3:
        return AppColors.borderSubtle;
    }
  }

  List<BoxShadow> get _defaultShadows {
    switch (widget.tier) {
      case GlassTier.level1:
        return [
          BoxShadow(
            color: const Color(0xFF1F2933).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ];
      case GlassTier.level2:
        return [
          BoxShadow(
            color: const Color(0xFF1F2933).withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      case GlassTier.level3:
        return [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.16),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = _hovered && widget.onTap != null
        ? AppColors.borderStrong
        : (widget.borderColor ?? _defaultBorderColor);

    final radius = BorderRadius.circular(widget.borderRadius);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surfaceCard,
        borderRadius: radius,
        border: Border.all(color: effectiveBorder, width: widget.borderWidth),
        boxShadow: widget.boxShadow ?? _defaultShadows,
      ),
      child: widget.child,
    );

    content = ClipRRect(
      borderRadius: radius,
      child: content,
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: content,
        ),
      );
    }

    if (widget.margin != null) {
      return Padding(padding: widget.margin!, child: content);
    }
    return content;
  }
}
