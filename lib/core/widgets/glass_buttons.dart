import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 1. Primary Button (Soft Indigo Tonal OR Brand Fill) — minHeight 48, radius 10
class GlassPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool useBrandFill;
  final bool expand;
  final Color? customColor;

  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.useBrandFill = true,
    this.expand = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = customColor ??
        (useBrandFill ? AppColors.primary : AppColors.primaryTonal);
    final fg = customColor != null
        ? Colors.white
        : (useBrandFill ? Colors.white : AppColors.primaryOnTonal);

    final button = SizedBox(
      width: expand ? double.infinity : null,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: onPressed != null && !loading && useBrandFill
              ? [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.45),
            disabledForegroundColor: fg.withValues(alpha: 0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: fg,
                            ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return MouseRegion(
      cursor: onPressed != null && !loading
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: button,
    );
  }
}

/// 2. Secondary Button (Dark Glass Fill)
class GlassSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const GlassSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: 48,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3. Inverted Button (Light Surface Fill — e.g. Unduh Laporan, Cetak Struk)
class GlassInvertedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool loading;

  const GlassInvertedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onPressed != null && !loading
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: 48,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.invertedSurface,
            foregroundColor: AppColors.neutral,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.neutral,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: AppColors.neutral),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.neutral,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 4. Outlined Button (Neutral or Destructive Coral)
class GlassOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDestructive;
  final bool expand;

  const GlassOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDestructive ? AppColors.errorLight : AppColors.invertedSurface;
    final border = isDestructive
        ? AppColors.error.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.24);

    return MouseRegion(
      cursor: onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(color: border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TonalIconVariant { indigo, emerald, amber, coral }

/// 5. Circular Tonal Icon Button (48x48 touch target, 40x40 tonal circle)
class GlassCircularTonalIcon extends StatelessWidget {
  final IconData icon;
  final TonalIconVariant variant;
  final VoidCallback? onPressed;
  final String? tooltip;

  const GlassCircularTonalIcon({
    super.key,
    required this.icon,
    required this.variant,
    required this.onPressed,
    this.tooltip,
  });

  Color get _bg {
    switch (variant) {
      case TonalIconVariant.indigo:
        return AppColors.primaryTonal;
      case TonalIconVariant.emerald:
        return AppColors.secondaryTonal;
      case TonalIconVariant.amber:
        return AppColors.tertiaryTonal;
      case TonalIconVariant.coral:
        return AppColors.errorTonal;
    }
  }

  Color get _fg {
    switch (variant) {
      case TonalIconVariant.indigo:
        return AppColors.primaryIconDark;
      case TonalIconVariant.emerald:
        return AppColors.secondaryOnTonal;
      case TonalIconVariant.amber:
        return AppColors.tertiaryOnTonal;
      case TonalIconVariant.coral:
        return AppColors.errorOnTonal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor: onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: _fg),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

/// 6. Extended Primary FAB (radius 12)
class GlassExtendedPrimaryFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const GlassExtendedPrimaryFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Icon(icon),
        label: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
