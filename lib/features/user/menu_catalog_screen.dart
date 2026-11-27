import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/pos_header.dart';
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
      barrierColor: const Color(0x730F172A),
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

  Widget _buildSearchCapsule({required bool elevated}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(16, 4, 5, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: elevated ? AppColors.borderDefault : AppColors.borderInput,
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
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              decoration: const InputDecoration(
                hintText: 'Cari kopi, makanan, atau camilan...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (_searchQuery.isNotEmpty) {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.accentTerracotta,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.close_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.accentTerracotta,
          backgroundColor: AppColors.surfaceCard,
          onRefresh: _loadMenus,
          child: CustomScrollView(
            slivers: [
              if (isMobile)
                SliverToBoxAdapter(
                  child: PosSlateHeader(
                    eyebrow: 'SELF-ORDER • QRIS POS',
                    title: 'Katalog Menu',
                    subtitle: 'Pilih menu favorit Anda lalu tunjukkan QR ke kasir.',
                    trailing: PosHeaderIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Muat ulang katalog',
                      onPressed: _loadMenus,
                    ),
                    straddleOverlap: 25,
                    straddlingChild: _buildSearchCapsule(elevated: true),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildSearchCapsule(elevated: false),
                        ),
                      ],
                    ),
                  ),
                ),

              // Section Header
              if (!_loading && _error == null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 24,
                    isMobile ? 16 : 12,
                    isMobile ? 20 : 24,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'Daftar Menu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.accentTerracotta,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredMenus.length} Pilihan',
                          style: AppFormatters.tabular(
                            theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentTerracotta,
                    ),
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
                              size: 42, color: AppColors.semanticError),
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
                    isMobile ? 20 : 24,
                    4,
                    isMobile ? 20 : 24,
                    _cart.isNotEmpty ? 104 : 28,
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
                          childAspectRatio: w < 420 ? 0.68 : 0.74,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Sticky Level 2 Checkout Bar
        if (_cart.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: GlassContainer(
                  tier: GlassTier.level2,
                  borderRadius: 18,
                  borderColor: AppColors.borderDefault,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.accentTerracotta,
                              size: 22,
                            ),
                          ),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
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
                                '$_totalItems',
                                style: AppFormatters.tabular(
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Sementara ($_totalItems Item)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              AppFormatters.rupiah(_totalAmount),
                              style: AppFormatters.tabular(
                                theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassPrimaryButton(
                        label: 'Checkout',
                        icon: Icons.chevron_right_rounded,
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
    );
  }
}

/// Tactile White Paper Menu Card
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
    final selected = quantity > 0;

    return GlassContainer(
      tier: GlassTier.level1,
      enableBlur: false,
      borderRadius: 16,
      borderColor: selected
          ? AppColors.accentTerracotta.withValues(alpha: 0.65)
          : AppColors.borderSubtle,
      borderWidth: selected ? 1.5 : 1,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with 14px border radius on #F1F4F7 placeholder well
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            flex: 2,
            child: Text(
              menu.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppFormatters.rupiah(menu.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFormatters.tabular(
                    theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (quantity == 0)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onAdd,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accentTerracotta,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentTerracotta
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepperBtn(icon: Icons.remove_rounded, onTap: onRemove),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          '$quantity',
                          style: AppFormatters.tabular(
                            theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
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
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: primary
                ? AppColors.accentTerracotta
                : AppColors.surfacePillInactive,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: primary ? Colors.white : AppColors.textPrimary,
          ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgCanvasDeep,
            Color(0xFFE7ECF2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isDrink ? Icons.local_cafe_rounded : Icons.restaurant_rounded,
          size: 38,
          color: AppColors.slateHeader.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
