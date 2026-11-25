import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_navigation.dart';
import '../../models/menu_item.dart';
import '../../models/user_profile.dart';
import '../../services/menu_service.dart';
import '../shared/profile_screen.dart';
import 'kasir_daily_history_screen.dart';
import 'kasir_scanner_screen.dart';

class KasirShell extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const KasirShell({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<KasirShell> createState() => _KasirShellState();
}

class _KasirShellState extends State<KasirShell> {
  int _selectedIndex = 0;
  int _historyRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    const items = [
      GlassNavItem(
        label: 'Scan QR',
        icon: Icons.qr_code_scanner_outlined,
        activeIcon: Icons.qr_code_scanner_rounded,
      ),
      GlassNavItem(
        label: 'Histori Hari Ini',
        icon: Icons.today_outlined,
        activeIcon: Icons.today_rounded,
      ),
      GlassNavItem(
        label: 'Daftar Menu',
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
      ),
      GlassNavItem(
        label: 'Profil',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = KasirScannerScreen(
          onOrderProcessed: () => setState(() => _historyRefreshKey++),
        );
      case 1:
        currentScreen = KasirDailyHistoryScreen(
          key: ValueKey(_historyRefreshKey),
        );
      case 2:
        currentScreen = const _KasirReadOnlyMenuScreen();
      default:
        currentScreen = ProfileScreen(
          profile: widget.profile,
          onProfileUpdated: widget.onProfileUpdated,
        );
    }

    return GlassNavigationShell(
      appTitle: 'GlassPOS Kasir',
      roleLabel: 'Kasir',
      userName: widget.profile.fullName,
      items: items,
      selectedIndex: _selectedIndex,
      onSelect: (idx) => setState(() => _selectedIndex = idx),
      showTertiaryOrb: true,
      child: currentScreen,
    );
  }
}

/// Read-only menu view for Kasir per PRD RBAC Matrix
class _KasirReadOnlyMenuScreen extends StatefulWidget {
  const _KasirReadOnlyMenuScreen();

  @override
  State<_KasirReadOnlyMenuScreen> createState() =>
      _KasirReadOnlyMenuScreenState();
}

class _KasirReadOnlyMenuScreenState extends State<_KasirReadOnlyMenuScreen> {
  final _menuService = MenuService();
  List<MenuItem> _menus = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _menuService.fetchActiveMenus();
      if (mounted) {
        setState(() {
          _menus = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daftar Menu Aktif (Read-Only)',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Referensi harga dan ketersediaan menu untuk verifikasi kasir.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 115),
                sliver: SliverList.separated(
                  itemCount: _menus.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final m = _menus[index];
                    return GlassContainer(
                      tier: GlassTier.level1,
                      enableBlur: false,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 3),
                                Text(
                                  m.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppFormatters.rupiah(m.price),
                            style: AppFormatters.tabular(
                              theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.tertiaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
