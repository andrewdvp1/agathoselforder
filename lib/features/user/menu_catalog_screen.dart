import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/cart_item.dart';
import '../../models/menu_item.dart';
import '../../models/order_model.dart';
import '../../services/menu_service.dart';
import '../../services/order_service.dart';
import 'checkout_sheet.dart';

class MenuCatalogScreen extends StatefulWidget {
  final ValueChanged<OrderModel> onOrderCreated;

  const MenuCatalogScreen({
    super.key,
    required this.onOrderCreated,
  });

  @override
  State<MenuCatalogScreen> createState() => _MenuCatalogScreenState();
}

class _MenuCatalogScreenState extends State<MenuCatalogScreen> {
  final _menuService = MenuService();
  final _orderService = OrderService();
  final _searchCtrl = TextEditingController();

  List<MenuItem> _menus = [];
  final Map<String, CartItem> _cart = {};
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _menuService.fetchActiveMenus();
      if (!mounted) return;
      setState(() {
        _menus = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<MenuItem> get _filteredMenus {
    if (_searchQuery.trim().isEmpty) return _menus;
    final q = _searchQuery.toLowerCase();
    return _menus
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q))
        .toList();
  }

  int get _totalItems =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  int get _totalAmount =>
      _cart.values.fold(0, (sum, item) => sum + item.subtotal);

  void _increment(MenuItem menu) {
    setState(() {
      final existing = _cart[menu.id];
      if (existing == null) {
        _cart[menu.id] = CartItem(menu: menu, quantity: 1);
      } else {
        _cart[menu.id] = existing.copyWith(quantity: existing.quantity + 1);
      }
    });
  }

  void _decrement(MenuItem menu) {
    setState(() {
      final existing = _cart[menu.id];
      if (existing == null) return;
      if (existing.quantity <= 1) {
        _cart.remove(menu.id);
      } else {
        _cart[menu.id] = existing.copyWith(quantity: existing.quantity - 1);
      }
    });
  }

  Future<void> _openCheckout() async {
    if (_cart.isEmpty) return;

    final createdOrder = await showModalBottomSheet<OrderModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckoutSheet(
        cartItems: _cart.values.toList(),
        orderService: _orderService,
      ),
    );

    if (createdOrder != null && mounted) {
      setState(() => _cart.clear());
      widget.onOrderCreated(createdOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceBase,
            onRefresh: _loadMenus,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Katalog Menu',
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pilih menu favorit Anda lalu tunjukkan QR ke kasir.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            GlassCircularTonalIcon(
                              icon: Icons.refresh_rounded,
                              variant: TonalIconVariant.indigo,
                              tooltip: 'Muat ulang katalog',
                              onPressed: _loadMenus,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Cari kopi, makanan, atau camilan...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 42, color: AppColors.errorLight),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 14),
                            GlassPrimaryButton(
                              label: 'Muat Ulang',
                              expand: false,
                              onPressed: _loadMenus,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_filteredMenus.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Menu tidak ditemukan.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      _cart.isNotEmpty
                          ? (isMobile ? 185 : 120)
                          : (isMobile ? 110 : 32),
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.crossAxisExtent;
                        final crossAxisCount = w > 1000
                            ? 4
                            : (w > 640 ? 3 : 2);
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final menu = _filteredMenus[index];
                              final qty = _cart[menu.id]?.quantity ?? 0;
                              return _MenuGridCard(
                                menu: menu,
                                quantity: qty,
                                onAdd: () => _increment(menu),
                                onRemove: () => _decrement(menu),
                              );
                            },
                            childCount: _filteredMenus.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: w < 420 ? 0.66 : 0.74,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Sticky Glass Level 2 Checkout Bar
          if (_cart.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: isMobile ? 92 : 20,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: GlassContainer(
                    tier: GlassTier.level2,
                    borderRadius: 16,
                    borderColor: AppColors.primary.withValues(alpha: 0.45),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '$_totalItems',
                              style: AppFormatters.tabular(
                                theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryTonal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total Sementara',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                AppFormatters.rupiah(_totalAmount),
                                style: AppFormatters.tabular(
                                  theme.textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GlassPrimaryButton(
                          label: 'Checkout',
                          icon: Icons.qr_code_2_rounded,
                          expand: false,
                          onPressed: _openCheckout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pseudo-Glass Menu Card (`enableBlur: false`) for smooth 60 FPS scrolling
class _MenuGridCard extends StatelessWidget {
  final MenuItem menu;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuGridCard({
    required this.menu,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      tier: GlassTier.level1,
      enableBlur: false, // Pseudo-Glass per Design System Section 3.3
      borderRadius: 16,
      borderColor: quantity > 0
          ? AppColors.primary.withValues(alpha: 0.65)
          : AppColors.borderGlassSubtle,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with 12px border radius
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: AppColors.bgCanvasDeep,
                child: menu.imageUrl != null
                    ? Image.network(
                        menu.imageUrl!,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                        errorBuilder: (_, _, _) => _PlaceholderArt(name: menu.name),
                      )
                    : _PlaceholderArt(name: menu.name),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            menu.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 2,
            child: Text(
              menu.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppFormatters.rupiah(menu.price),
                  style: AppFormatters.tabular(
                    theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.tertiaryLight,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (quantity == 0)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTonal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.primaryOnTonal,
                        size: 20,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepperBtn(icon: Icons.remove_rounded, onTap: onRemove),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$quantity',
                        style: AppFormatters.tabular(
                          theme.textTheme.labelLarge,
                        ),
                      ),
                    ),
                    _StepperBtn(
                      icon: Icons.add_rounded,
                      onTap: onAdd,
                      primary: true,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _StepperBtn({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: primary
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _PlaceholderArt extends StatelessWidget {
  final String name;
  const _PlaceholderArt({required this.name});

  @override
  Widget build(BuildContext context) {
    final lower = name.toLowerCase();
    final isDrink = lower.contains('kopi') ||
        lower.contains('teh') ||
        lower.contains('latte') ||
        lower.contains('americano') ||
        lower.contains('matcha');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isDrink ? Icons.local_cafe_rounded : Icons.restaurant_rounded,
          size: 42,
          color: AppColors.primaryTonal.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
