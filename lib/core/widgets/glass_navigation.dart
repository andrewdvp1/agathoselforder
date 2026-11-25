import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'glass_scaffold.dart';

class GlassNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badgeCount;

  const GlassNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount = 0,
  });
}

/// Responsive Glassmorphic Shell implementing Breakpoints in Design System Section 5.3:
/// - Mobile (<600px): Floating Glass Capsule Bottom Navigation Pill
/// - Tablet (600-1024px): Glass Navigation Rail (72px)
/// - Desktop Web (>1024px): Glass Sidebar Panel (250px)
class GlassNavigationShell extends StatelessWidget {
  final String appTitle;
  final String roleLabel;
  final String userName;
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget child;
  final Widget? floatingActionButton;
  final bool showTertiaryOrb;

  const GlassNavigationShell({
    super.key,
    required this.appTitle,
    required this.roleLabel,
    required this.userName,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.child,
    this.floatingActionButton,
    this.showTertiaryOrb = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width > 1024;
        final isTablet = width >= 600 && width <= 1024;

        if (isDesktop || isTablet) {
          return GlassScaffold(
            showTertiaryOrb: showTertiaryOrb,
            floatingActionButton: floatingActionButton,
            body: SafeArea(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                    child: isDesktop
                        ? _GlassSidebar(
                            appTitle: appTitle,
                            roleLabel: roleLabel,
                            userName: userName,
                            items: items,
                            selectedIndex: selectedIndex,
                            onSelect: onSelect,
                          )
                        : _GlassNavRail(
                            items: items,
                            selectedIndex: selectedIndex,
                            onSelect: onSelect,
                          ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          );
        }

        // Mobile (<600px): Floating Glass Capsule Bottom Navigation Pill
        return GlassScaffold(
          showTertiaryOrb: showTertiaryOrb,
          floatingActionButton: floatingActionButton != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 76),
                  child: floatingActionButton,
                )
              : null,
          body: Stack(
            children: [
              Positioned.fill(child: child),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: _FloatingCapsuleNav(
                    items: items,
                    selectedIndex: selectedIndex,
                    onSelect: onSelect,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingCapsuleNav extends StatelessWidget {
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _FloatingCapsuleNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      tier: GlassTier.level2,
      borderRadius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (idx) {
          final item = items[idx];
          final active = idx == selectedIndex;
          return Tooltip(
            message: item.label,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(idx),
                child: SizedBox(
                  width: 52,
                  height: 48,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primaryTonal
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            active ? item.activeIcon : item.icon,
                            size: 22,
                            color: active
                                ? AppColors.primaryOnTonal
                                : AppColors.textInactiveIcon,
                          ),
                        ),
                        if (item.badgeCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${item.badgeCount}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neutral,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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

class _GlassNavRail extends StatelessWidget {
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _GlassNavRail({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      tier: GlassTier.level2,
      width: 72,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.primaryTonal, size: 22),
          ),
          const SizedBox(height: 24),
          ...List.generate(items.length, (idx) {
            final item = items[idx];
            final active = idx == selectedIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Tooltip(
                message: item.label,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onSelect(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryTonal
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        active ? item.activeIcon : item.icon,
                        color: active
                            ? AppColors.primaryOnTonal
                            : AppColors.textInactiveIcon,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GlassSidebar extends StatelessWidget {
  final String appTitle;
  final String roleLabel;
  final String userName;
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _GlassSidebar({
    required this.appTitle,
    required this.roleLabel,
    required this.userName,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      tier: GlassTier.level2,
      width: 250,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: AppColors.primaryTonal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appTitle,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      roleLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(items.length, (idx) {
            final item = items[idx];
            final active = idx == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onSelect(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryTonal
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 20,
                          color: active
                              ? AppColors.primaryOnTonal
                              : AppColors.textInactiveIcon,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: active
                                  ? AppColors.primaryOnTonal
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.badgeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${item.badgeCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral,
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
          const Spacer(),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryTonal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      roleLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
