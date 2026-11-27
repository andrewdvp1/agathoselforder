import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/pos_header.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final _menuService = MenuService();
  final _searchCtrl = TextEditingController();

  List<MenuItem> _menus = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _filter = 'active'; // active | all | deleted

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
      final list = await _menuService.fetchAllMenusForAdmin(includeDeleted: true);
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
    return _menus.where((m) {
      if (_filter == 'active' && (m.isDeleted || !m.isActive)) return false;
      if (_filter == 'deleted' && !m.isDeleted) return false;
      if (_search.trim().isNotEmpty) {
        final q = _search.toLowerCase();
        if (!m.name.toLowerCase().contains(q) &&
            !m.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> openCreateOrEditDialog({MenuItem? editing}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x730F172A),
      builder: (_) => _MenuCrudDialog(
        menuService: _menuService,
        editing: editing,
      ),
    );
    if (saved == true) {
      await _loadMenus();
    }
  }

  Future<void> _confirmSoftDelete(MenuItem menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x730F172A),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: GlassContainer(
            tier: GlassTier.level3,
            borderRadius: 20,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.semanticErrorSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.semanticError,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Arsipkan Menu?',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Menu "${menu.name}" akan disembunyikan dari katalog pengunjung, namun riwayat transaksi lama tetap utuh.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GlassOutlinedButton(
                        label: 'Batal',
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassPrimaryButton(
                        label: 'Hapus Menu',
                        customColor: AppColors.semanticError,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _menuService.softDeleteMenu(menu.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu "${menu.name}" berhasil dihapus (soft delete).'),
        ),
      );
      await _loadMenus();
    }
  }

  Widget _buildSearchCapsule({required bool elevated}) {
    return Container(
      height: 48,
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
              onChanged: (v) => setState(() => _search = v),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              decoration: const InputDecoration(
                hintText: 'Cari nama atau deskripsi menu...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_search.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _search = '');
              },
              icon: const Icon(Icons.close_rounded, size: 18),
            )
          else if (elevated)
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.accentTerracotta,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 18,
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
    final activeCount =
        _menus.where((m) => !m.isDeleted && m.isActive).length;
    final archivedOrInactiveCount =
        _menus.where((m) => m.isDeleted || !m.isActive).length;

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
                    eyebrow: 'KATALOG PRODUK • CRUD',
                    title: 'Manajemen Menu',
                    subtitle: 'Kelola menu, foto Supabase Storage (<= 2 MB) & harga.',
                    trailing: PosHeaderIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Muat ulang',
                      onPressed: _loadMenus,
                    ),
                    straddleOverlap: 24,
                    straddlingChild: _buildSearchCapsule(elevated: true),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
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
                                    'Manajemen Katalog Menu (CRUD)',
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kelola nama, gambar (Supabase Storage <= 2 MB), deskripsi, dan harga secara real-time.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GlassPrimaryButton(
                              label: 'Tambah Menu',
                              icon: Icons.add_rounded,
                              expand: false,
                              onPressed: () => openCreateOrEditDialog(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Filter Bar + Summary Strip
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 20 : 24,
                  isMobile ? 16 : 8,
                  isMobile ? 20 : 24,
                  10,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile) ...[
                        GlassContainer(
                          tier: GlassTier.level1,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSearchCapsule(elevated: false),
                              ),
                              const SizedBox(width: 12),
                              _SummaryPill(
                                label: 'Aktif: $activeCount',
                                bg: AppColors.semanticSuccessSoft,
                                fg: AppColors.semanticSuccess,
                              ),
                              const SizedBox(width: 8),
                              _SummaryPill(
                                label: 'Nonaktif/Arsip: $archivedOrInactiveCount',
                                bg: AppColors.semanticWarningSoft,
                                fg: AppColors.statusPendingText,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: GlassContainer(
                                tier: GlassTier.level1,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Aktif',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        Text(
                                          '$activeCount Menu',
                                          style: AppFormatters.tabular(
                                            theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                      color: AppColors.slateHeader,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GlassContainer(
                                tier: GlassTier.level1,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Arsip/Nonaktif',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        Text(
                                          '$archivedOrInactiveCount Item',
                                          style: AppFormatters.tabular(
                                            theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: AppColors.accentTerracotta,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.archive_outlined,
                                      size: 20,
                                      color: AppColors.accentTerracotta,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChipPill(
                            label: 'Aktif',
                            selected: _filter == 'active',
                            onTap: () => setState(() => _filter = 'active'),
                          ),
                          _FilterChipPill(
                            label: 'Semua Menu (${_menus.length})',
                            selected: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          _FilterChipPill(
                            label: 'Arsip / Terhapus',
                            selected: _filter == 'deleted',
                            onTap: () => setState(() => _filter = 'deleted'),
                          ),
                        ],
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
                SliverFillRemaining(child: Center(child: Text(_error!)))
              else if (_filteredMenus.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Tidak ada menu pada filter ini.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 24,
                    6,
                    isMobile ? 20 : 24,
                    isMobile ? 96 : 36,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _filteredMenus.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final menu = _filteredMenus[index];
                      return GlassContainer(
                        tier: GlassTier.level1,
                        enableBlur: false,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: isMobile ? 68 : 60,
                                    height: isMobile ? 68 : 60,
                                    color: AppColors.bgCanvasDeep,
                                    child: menu.imageUrl != null
                                        ? Image.network(
                                            menu.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                              Icons.fastfood_rounded,
                                              color: AppColors.slateHeader,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.restaurant_rounded,
                                            color: AppColors.slateHeader,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              menu.name,
                                              style:
                                                  theme.textTheme.titleMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: menu.isDeleted
                                                  ? AppColors.semanticErrorSoft
                                                  : (menu.isActive
                                                      ? AppColors
                                                          .semanticSuccessSoft
                                                      : AppColors
                                                          .surfacePillInactive),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              menu.isDeleted
                                                  ? 'Terhapus'
                                                  : (menu.isActive
                                                      ? 'Aktif'
                                                      : 'Nonaktif'),
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                fontSize: 10,
                                                color: menu.isDeleted
                                                    ? AppColors.semanticError
                                                    : (menu.isActive
                                                        ? AppColors
                                                            .semanticSuccess
                                                        : AppColors
                                                            .textSecondary),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        menu.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (!isMobile) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          AppFormatters.rupiah(menu.price),
                                          style: AppFormatters.tabular(
                                            theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!isMobile) ...[
                                  const SizedBox(width: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!menu.isDeleted) ...[
                                        Switch(
                                          value: menu.isActive,
                                          onChanged: (v) async {
                                            await _menuService.toggleMenuActive(
                                                menu.id, v);
                                            await _loadMenus();
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        GlassCircularTonalIcon(
                                          icon: Icons.edit_rounded,
                                          variant: TonalIconVariant.indigo,
                                          tooltip: 'Edit menu',
                                          onPressed: () =>
                                              openCreateOrEditDialog(
                                                  editing: menu),
                                        ),
                                        GlassCircularTonalIcon(
                                          icon: Icons.delete_outline_rounded,
                                          variant: TonalIconVariant.coral,
                                          tooltip: 'Soft delete menu',
                                          onPressed: () =>
                                              _confirmSoftDelete(menu),
                                        ),
                                      ] else
                                        GlassCircularTonalIcon(
                                          icon: Icons.restore_rounded,
                                          variant: TonalIconVariant.emerald,
                                          tooltip: 'Pulihkan menu',
                                          onPressed: () async {
                                            await _menuService
                                                .restoreMenu(menu.id);
                                            await _loadMenus();
                                          },
                                        ),
                                    ],
                                  ),
                                ] else if (!menu.isDeleted)
                                  Switch(
                                    value: menu.isActive,
                                    onChanged: (v) async {
                                      await _menuService.toggleMenuActive(
                                          menu.id, v);
                                      await _loadMenus();
                                    },
                                  ),
                              ],
                            ),
                            if (isMobile) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppFormatters.rupiah(menu.price),
                                      style: AppFormatters.tabular(
                                        theme.textTheme.titleMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!menu.isDeleted) ...[
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: () => openCreateOrEditDialog(
                                            editing: menu),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.surfacePillInactive,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color: AppColors.textPrimary,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Edit',
                                                style: theme
                                                    .textTheme.labelMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: () => _confirmSoftDelete(menu),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.semanticErrorSoft,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: AppColors.semanticError,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else
                                    GlassOutlinedButton(
                                      label: 'Pulihkan',
                                      icon: Icons.restore_rounded,
                                      onPressed: () async {
                                        await _menuService.restoreMenu(menu.id);
                                        await _loadMenus();
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        if (isMobile)
          Positioned(
            right: 20,
            bottom: 16,
            child: GlassExtendedPrimaryFab(
              label: 'Tambah Menu',
              icon: Icons.add_rounded,
              onPressed: () => openCreateOrEditDialog(),
            ),
          ),
      ],
    );
  }
}

class _MenuCrudDialog extends StatefulWidget {
  final MenuService menuService;
  final MenuItem? editing;

  const _MenuCrudDialog({
    required this.menuService,
    this.editing,
  });

  @override
  State<_MenuCrudDialog> createState() => _MenuCrudDialogState();
}

class _MenuCrudDialogState extends State<_MenuCrudDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;

  bool _isActive = true;
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _priceCtrl = TextEditingController(text: e != null ? '${e.price}' : '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedFileName = picked.name;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memilih gambar: $e');
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final price =
        int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (price <= 0) {
      setState(() => _error = 'Harga harus berupa bilangan Rupiah positif.');
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.editing == null) {
        await widget.menuService.createMenu(
          name: _nameCtrl.text,
          description: _descCtrl.text,
          price: price,
          isActive: _isActive,
          imageBytes: _pickedBytes,
          imageFileName: _pickedFileName,
        );
      } else {
        await widget.menuService.updateMenu(
          id: widget.editing!.id,
          name: _nameCtrl.text,
          description: _descCtrl.text,
          price: price,
          isActive: _isActive,
          newImageBytes: _pickedBytes,
          newImageFileName: _pickedFileName,
          existingImagePath: widget.editing!.imagePath,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.editing != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassContainer(
          tier: GlassTier.level3,
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Slate Blue Modal Header Cap
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 16, 14, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.slateHeader, Color(0xFF273E4C)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.accentTerracotta,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_note_rounded
                                : Icons.add_business_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Menu' : 'Tambah Menu Baru',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cross-platform Image Picker Preview
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.bgCanvas,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderStrong,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 84,
                                      height: 84,
                                      color: AppColors.bgCanvasDeep,
                                      child: _pickedBytes != null
                                          ? Image.memory(
                                              _pickedBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : (widget.editing?.imageUrl != null
                                              ? Image.network(
                                                  widget.editing!.imageUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                  size: 32,
                                                  color: AppColors.slateHeader,
                                                )),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pickedBytes != null ||
                                                  widget.editing?.imageUrl !=
                                                      null
                                              ? 'Foto Menu Terpilih'
                                              : 'Unggah Gambar Menu',
                                          style: theme.textTheme.labelLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'JPG, PNG, WebP (Maks. 2 MB)',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceCard,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: AppColors.borderDefault,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.upload_rounded,
                                                size: 15,
                                                color: AppColors.slateHeader,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _pickedBytes != null ||
                                                        widget.editing
                                                                ?.imageUrl !=
                                                            null
                                                    ? 'Ganti Foto'
                                                    : 'Pilih Foto',
                                                style:
                                                    theme.textTheme.labelMedium,
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
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Menu',
                            hintText: 'Contoh: Kopi Susu Gula Aren',
                          ),
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'Nama menu wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga (Rupiah)',
                            hintText: '25000',
                            prefixText: 'Rp ',
                          ),
                          validator: (v) {
                            final n = int.tryParse(
                                    (v ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                                0;
                            if (n <= 0) return 'Harga wajib bilangan positif';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi Menu',
                            hintText: 'Jelaskan bahan, rasa, atau porsi menu...',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Deskripsi menu wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgCanvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _isActive,
                            title: Text(
                              'Status Ketersediaan',
                              style: theme.textTheme.labelLarge,
                            ),
                            subtitle: Text(
                              _isActive
                                  ? 'Tersedia di Katalog Pengunjung'
                                  : 'Disembunyikan sementara',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _isActive
                                    ? AppColors.semanticSuccess
                                    : AppColors.textSecondary,
                              ),
                            ),
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.semanticError,
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: GlassOutlinedButton(
                                label: 'Batal',
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GlassPrimaryButton(
                                label: isEdit ? 'Simpan Menu' : 'Buat Menu',
                                icon: Icons.check_rounded,
                                loading: _saving,
                                onPressed: _save,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _SummaryPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppFormatters.tabular(
          Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
        ),
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentTerracotta
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.accentTerracotta
                  : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}
