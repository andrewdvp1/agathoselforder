import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GlassTier {
  level1, // Card / Panel: sigma 10-12
  level2, // Navigation / Bar / QR Card: sigma 16-20
  level3, // Modal / Overlay: sigma 20-24
}

/// Mandatory Reusable Widget #2: GlassContainer
/// Supports 3 glass elevation tiers and `enableBlur: false` (Pseudo-Glass) for
/// smooth 60 FPS scrolling inside long ListView/GridView lists.
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
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _hovered = false;

  double get _sigma {
    switch (widget.tier) {
      case GlassTier.level1:
        return 11;
      case GlassTier.level2:
        return 18;
      case GlassTier.level3:
        return 22;
    }
  }

  List<Color> get _gradientColors {
    switch (widget.tier) {
      case GlassTier.level1:
        return [
          const Color(0x991E293B),
          const Color(0x7A1E293B),
        ];
      case GlassTier.level2:
        return [
          const Color(0xB81E293B), // rgba(30,41,59,0.72)
          const Color(0xA60F172A), // rgba(15,23,42,0.65)
        ];
      case GlassTier.level3:
        return [
          const Color(0xD90F172A), // rgba(15,23,42,0.85)
          const Color(0xC71E293B), // rgba(30,41,59,0.78)
        ];
    }
  }

  Color get _defaultBorderColor {
    switch (widget.tier) {
      case GlassTier.level1:
        return AppColors.borderGlassSubtle;
      case GlassTier.level2:
        return AppColors.borderGlassMedium;
      case GlassTier.level3:
        return AppColors.borderGlassModal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = _hovered && widget.onTap != null
        ? AppColors.borderGlassHover
        : (widget.borderColor ?? _defaultBorderColor);

    final radius = BorderRadius.circular(widget.borderRadius);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        border: Border.all(color: effectiveBorder, width: widget.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.tier == GlassTier.level3 ? 0.36 : 0.2),
            blurRadius: widget.tier == GlassTier.level3 ? 28 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.enableBlur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: radius,
        child: content,
      );
    }

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
