import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.65),
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
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: GlassContainer(
            tier: GlassTier.level3,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Arsipkan Menu (Soft Delete)?',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
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
                        customColor: AppColors.error,
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
        SnackBar(content: Text('Menu "${menu.name}" berhasil dihapus (soft delete).')),
      );
      await _loadMenus();
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
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Manajemen Menu (CRUD)',
                                      style: theme.textTheme.headlineMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kelola nama, gambar (Supabase Storage <= 2 MB), deskripsi, dan harga.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile)
                              GlassPrimaryButton(
                                label: 'Tambah Menu',
                                icon: Icons.add_rounded,
                                expand: false,
                                onPressed: () => openCreateOrEditDialog(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _search = v),
                                decoration: const InputDecoration(
                                  hintText: 'Cari nama atau deskripsi menu...',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                              label: 'Semua Menu',
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
                        child:
                            CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (_error != null)
                  SliverFillRemaining(child: Center(child: Text(_error!)))
                else if (_filteredMenus.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text('Tidak ada menu pada filter ini.',
                          style: theme.textTheme.bodyLarge),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        20, 6, 20, isMobile ? 165 : 40),
                    sliver: SliverList.separated(
                      itemCount: _filteredMenus.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final menu = _filteredMenus[index];
                        return GlassContainer(
                          tier: GlassTier.level1,
                          enableBlur: false, // Pseudo-Glass 60 FPS
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  color: AppColors.bgCanvasDeep,
                                  child: menu.imageUrl != null
                                      ? Image.network(
                                          menu.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Icon(
                                                  Icons.fastfood_rounded,
                                                  color:
                                                      AppColors.primaryTonal),
                                        )
                                      : const Icon(Icons.restaurant_rounded,
                                          color: AppColors.primaryTonal),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            menu.name,
                                            style: theme.textTheme.titleMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: menu.isDeleted
                                                ? AppColors.statusRejectedBg
                                                : (menu.isActive
                                                    ? AppColors.statusPaidBg
                                                    : AppColors.statusExpiredBg),
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
                                                  ? AppColors.errorLight
                                                  : (menu.isActive
                                                      ? AppColors.secondaryLight
                                                      : AppColors.textSecondary),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      menu.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppFormatters.rupiah(menu.price),
                                      style: AppFormatters.tabular(
                                        theme.textTheme.titleMedium?.copyWith(
                                          color: AppColors.tertiaryLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Circular Tonal Action Icons (Design System 6.1)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!menu.isDeleted) ...[
                                    GlassCircularTonalIcon(
                                      icon: menu.isActive
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      variant: TonalIconVariant.emerald,
                                      tooltip: menu.isActive
                                          ? 'Nonaktifkan sementara'
                                          : 'Aktifkan menu',
                                      onPressed: () async {
                                        await _menuService.toggleMenuActive(
                                            menu.id, !menu.isActive);
                                        await _loadMenus();
                                      },
                                    ),
                                    GlassCircularTonalIcon(
                                      icon: Icons.edit_rounded,
                                      variant: TonalIconVariant.amber,
                                      tooltip: 'Edit menu',
                                      onPressed: () =>
                                          openCreateOrEditDialog(editing: menu),
                                    ),
                                    GlassCircularTonalIcon(
                                      icon: Icons.delete_outline_rounded,
                                      variant: TonalIconVariant.coral,
                                      tooltip: 'Soft delete menu',
                                      onPressed: () => _confirmSoftDelete(menu),
                                    ),
                                  ] else
                                    GlassCircularTonalIcon(
                                      icon: Icons.restore_rounded,
                                      variant: TonalIconVariant.emerald,
                                      tooltip: 'Pulihkan menu',
                                      onPressed: () async {
                                        await _menuService.restoreMenu(menu.id);
                                        await _loadMenus();
                                      },
                                    ),
                                ],
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

          if (isMobile)
            Positioned(
              right: 20,
              bottom: 94,
              child: GlassExtendedPrimaryFab(
                label: 'Tambah Menu',
                icon: Icons.add_rounded,
                onPressed: () => openCreateOrEditDialog(),
              ),
            ),
        ],
      ),
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

    final price = int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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
        constraints: const BoxConstraints(maxWidth: 500),
        child: GlassContainer(
          tier: GlassTier.level3,
          borderRadius: 20,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit Menu' : 'Tambah Menu Baru',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Cross-platform Image Picker Preview
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderGlassInput),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _pickedBytes != null
                            ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                            : (widget.editing?.imageUrl != null
                                ? Image.network(widget.editing!.imageUrl!,
                                    fit: BoxFit.cover)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 38,
                                          color: AppColors.primaryTonal),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Unggah Gambar Menu (JPG/PNG/WebP, maks 2 MB)',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ],
                                  )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

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
                  const SizedBox(height: 10),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    activeThumbColor: AppColors.secondary,
                    title: Text('Tampilkan di Katalog Pengunjung',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textPrimary)),
                    onChanged: (v) => setState(() => _isActive = v),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.errorTonal),
                    ),
                  ],

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GlassOutlinedButton(
                          label: 'Batal',
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassPrimaryButton(
                          label: isEdit ? 'Simpan Perubahan' : 'Buat Menu',
                          loading: _saving,
                          onPressed: _save,
                        ),
                      ),
                    ],
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryTonal
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderGlassSubtle,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      selected ? AppColors.primaryOnTonal : AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}
