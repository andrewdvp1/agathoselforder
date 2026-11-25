import 'package:flutter/material.dart';
import '../../core/widgets/glass_navigation.dart';
import '../../models/user_profile.dart';
import '../shared/profile_screen.dart';
import 'admin_menu_screen.dart';
import 'admin_reports_screen.dart';

class AdminShell extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const AdminShell({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const items = [
      GlassNavItem(
        label: 'Laporan & Histori',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
      ),
      GlassNavItem(
        label: 'Manajemen Menu',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
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
        currentScreen = const AdminReportsScreen();
      case 1:
        currentScreen = const AdminMenuScreen();
      default:
        currentScreen = ProfileScreen(
          profile: widget.profile,
          onProfileUpdated: widget.onProfileUpdated,
        );
    }

    return GlassNavigationShell(
      appTitle: 'GlassPOS Admin',
      roleLabel: 'Admin',
      userName: widget.profile.fullName,
      items: items,
      selectedIndex: _selectedIndex,
      onSelect: (idx) => setState(() => _selectedIndex = idx),
      showTertiaryOrb: true,
      child: currentScreen,
    );
  }
}
