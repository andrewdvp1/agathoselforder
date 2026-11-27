import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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

/// Responsive Terracotta & Slate POS Navigation Shell:
/// - Mobile (<600px): Elevated Pure White Docked Bottom Navigation Bar
/// - Tablet (600-1024px): Deep Slate Blue Navigation Rail (76px)
/// - Desktop (>1024px): Deep Slate Blue Persistent Sidebar (250px)
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
            body: Row(
              children: [
                isDesktop
                    ? _SlateSidebar(
                        appTitle: appTitle,
                        roleLabel: roleLabel,
                        userName: userName,
                        items: items,
                        selectedIndex: selectedIndex,
                        onSelect: onSelect,
                      )
                    : _SlateNavRail(
                        items: items,
                        selectedIndex: selectedIndex,
                        onSelect: onSelect,
                      ),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Mobile (<600px): Elevated White Bottom Navigation Deck
        return GlassScaffold(
          showTertiaryOrb: showTertiaryOrb,
          extendBody: false,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: _MobileBottomNavBar(
            items: items,
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          body: child,
        );
      },
    );
  }
}

class _MobileBottomNavBar extends StatelessWidget {
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _MobileBottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2933).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (idx) {
              final item = items[idx];
              final active = idx == selectedIndex;
              final fgColor = active
                  ? AppColors.accentTerracotta
                  : AppColors.textSecondary;

              return Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(idx),
                    child: SizedBox(
                      height: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.accentSoft
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Icon(
                                  active ? item.activeIcon : item.icon,
                                  size: 22,
                                  color: fgColor,
                                ),
                              ),
                              if (item.badgeCount > 0)
                                Positioned(
                                  right: 2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentTerracotta,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${item.badgeCount}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w500,
                              color: fgColor,
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
        ),
      ),
    );
  }
}

class _SlateNavRail extends StatelessWidget {
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SlateNavRail({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: double.infinity,
      color: AppColors.slateSidebar,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentTerracotta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 22,
                ),
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.accentTerracotta
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                active ? item.activeIcon : item.icon,
                                color: active
                                    ? Colors.white
                                    : AppColors.onSlateMuted,
                              ),
                            ),
                            if (item.badgeCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTerracotta,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.slateSidebar,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${item.badgeCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SlateSidebar extends StatelessWidget {
  final String appTitle;
  final String roleLabel;
  final String userName;
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SlateSidebar({
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
    return Container(
      width: 250,
      height: double.infinity,
      color: AppColors.slateSidebar,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Block
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentTerracotta,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSlateMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              ...List.generate(items.length, (idx) {
                final item = items[idx];
                final active = idx == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
                              ? AppColors.accentTerracotta
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              active ? item.activeIcon : item.icon,
                              size: 20,
                              color:
                                  active ? Colors.white : AppColors.onSlateMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: active
                                      ? Colors.white
                                      : AppColors.onSlateMuted,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (item.badgeCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white
                                      : AppColors.accentTerracotta,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${item.badgeCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? AppColors.accentTerracotta
                                        : Colors.white,
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slateSidebarFooter,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accentTerracotta,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
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
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            roleLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSlateMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
