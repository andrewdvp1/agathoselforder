import 'package:flutter/material.dart';
import '../../core/widgets/glass_navigation.dart';
import '../../models/order_model.dart';
import '../../models/user_profile.dart';
import '../shared/profile_screen.dart';
import 'menu_catalog_screen.dart';
import 'order_qr_status_screen.dart';
import 'user_history_screen.dart';

class UserShell extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const UserShell({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _selectedIndex = 0;
  OrderModel? _activeOrder;

  bool get _hasLiveOrder =>
      _activeOrder != null &&
      (_activeOrder!.status == OrderStatus.pendingVerification ||
          _activeOrder!.status == OrderStatus.paymentProcessing);

  @override
  Widget build(BuildContext context) {
    final items = [
      const GlassNavItem(
        label: 'Menu',
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu_rounded,
      ),
      GlassNavItem(
        label: 'QR Pesanan',
        icon: Icons.qr_code_2_outlined,
        activeIcon: Icons.qr_code_2_rounded,
        badgeCount: _hasLiveOrder ? 1 : 0,
      ),
      const GlassNavItem(
        label: 'Riwayat',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
      ),
      const GlassNavItem(
        label: 'Profil',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = MenuCatalogScreen(
          onOrderCreated: (order) {
            setState(() {
              _activeOrder = order;
              _selectedIndex = 1;
            });
          },
        );
      case 1:
        currentScreen = OrderQrStatusScreen(
          initialOrder: _activeOrder,
          onCreateNewOrder: () => setState(() => _selectedIndex = 0),
          onOrderUpdated: (updated) => setState(() => _activeOrder = updated),
        );
      case 2:
        currentScreen = UserHistoryScreen(
          onOpenActiveOrder: (order) {
            setState(() {
              _activeOrder = order;
              _selectedIndex = 1;
            });
          },
        );
      default:
        currentScreen = ProfileScreen(
          profile: widget.profile,
          onProfileUpdated: widget.onProfileUpdated,
        );
    }

    return GlassNavigationShell(
      appTitle: 'GlassPOS QR',
      roleLabel: 'Pengunjung',
      userName: widget.profile.fullName,
      items: items,
      selectedIndex: _selectedIndex,
      onSelect: (idx) => setState(() => _selectedIndex = idx),
      child: currentScreen,
    );
  }
}
