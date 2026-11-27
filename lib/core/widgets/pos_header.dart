import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Deep Slate Blue (#334E5E) structural top header cap with optional
/// straddling floating module overlapping the bottom boundary onto #F7F8FA canvas.
class PosSlateHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottomContent;
  final Widget? straddlingChild;
  final double straddleOverlap;

  const PosSlateHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.leading,
    this.trailing,
    this.bottomContent,
    this.straddlingChild,
    this.straddleOverlap = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerContainer = Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.slateHeader,
            Color(0xFF273E4C),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            straddlingChild != null ? 18 + straddleOverlap : 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSlateMuted,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.onSlate,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSlateMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              if (bottomContent != null) ...[
                const SizedBox(height: 12),
                bottomContent!,
              ],
            ],
          ),
        ),
      ),
    );

    if (straddlingChild == null) {
      return headerContainer;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: straddleOverlap),
          child: headerContainer,
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: straddlingChild!,
        ),
      ],
    );
  }
}

class PosSegmentedTabItem {
  final String label;
  final IconData? icon;

  const PosSegmentedTabItem({
    required this.label,
    this.icon,
  });
}

/// Floating segmented capsule tabs with Warm Terracotta (#E85D3F) active pill.
class PosSegmentedTabs extends StatelessWidget {
  final List<PosSegmentedTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool elevated;

  const PosSegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: elevated ? AppColors.surfaceCard : AppColors.surfacePillInactive,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: elevated ? AppColors.borderDefault : AppColors.borderSubtle,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: const Color(0xFF1F2933).withValues(alpha: 0.09),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: List.generate(items.length, (idx) {
          final item = items[idx];
          final active = idx == selectedIndex;
          return Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accentTerracotta
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.accentTerracotta
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: 16,
                          color: active
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: active
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Circular translucent slate icon button for dark Slate Blue headers.
class PosHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const PosHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
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
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
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
