import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/image_compressor.dart';
import '../models/menu_item.dart';

class MenuService {
  final SupabaseClient _client;

  MenuService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  String? resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return _client.storage
        .from(SupabaseConfig.menuImagesBucket)
        .getPublicUrl(imagePath);
  }

  Future<List<MenuItem>> fetchActiveMenus() async {
    final rows = await _client
        .from('menus')
        .select('*')
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .order('name');

    return (rows as List<dynamic>).map((raw) {
      final map = raw as Map<String, dynamic>;
      return MenuItem.fromJson(
        map,
        resolvedImageUrl: resolveImageUrl(map['image_path'] as String?),
      );
    }).toList();
  }

  Future<List<MenuItem>> fetchAllMenusForAdmin({bool includeDeleted = true}) async {
    var query = _client.from('menus').select('*');
    if (!includeDeleted) {
      query = query.isFilter('deleted_at', null);
    }
    final rows = await query.order('updated_at', ascending: false);

    return (rows as List<dynamic>).map((raw) {
      final map = raw as Map<String, dynamic>;
      return MenuItem.fromJson(
        map,
        resolvedImageUrl: resolveImageUrl(map['image_path'] as String?),
      );
    }).toList();
  }

  Future<String> _uploadMenuImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final compressed = ImageCompressor.compressForMenuUpload(bytes, fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'\.[^.]+$'), '');
    final storagePath = 'menus/${timestamp}_$safeName.${compressed.extension}';

    await _client.storage.from(SupabaseConfig.menuImagesBucket).uploadBinary(
          storagePath,
          compressed.bytes,
          fileOptions: FileOptions(
            contentType: compressed.contentType,
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return storagePath;
  }

  Future<MenuItem> createMenu({
    required String name,
    required String description,
    required int price,
    bool isActive = true,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    if (name.trim().length < 2) {
      throw Exception('Nama menu wajib diisi minimal 2 karakter.');
    }
    if (price <= 0) {
      throw Exception('Harga harus berupa bilangan Rupiah positif.');
    }

    String? imagePath;
    if (imageBytes != null && imageFileName != null) {
      imagePath = await _uploadMenuImage(
        bytes: imageBytes,
        fileName: imageFileName,
      );
    }

    final row = await _client
        .from('menus')
        .insert({
          'name': name.trim(),
          'description': description.trim(),
          'price': price,
          'is_active': isActive,
          'image_path': imagePath,
        })
        .select('*')
        .single();

    return MenuItem.fromJson(
      row,
      resolvedImageUrl: resolveImageUrl(row['image_path'] as String?),
    );
  }

  Future<MenuItem> updateMenu({
    required String id,
    required String name,
    required String description,
    required int price,
    required bool isActive,
    Uint8List? newImageBytes,
    String? newImageFileName,
    String? existingImagePath,
  }) async {
    if (name.trim().length < 2) {
      throw Exception('Nama menu wajib diisi minimal 2 karakter.');
    }
    if (price <= 0) {
      throw Exception('Harga harus berupa bilangan Rupiah positif.');
    }

    String? imagePath = existingImagePath;
    if (newImageBytes != null && newImageFileName != null) {
      imagePath = await _uploadMenuImage(
        bytes: newImageBytes,
        fileName: newImageFileName,
      );
    }

    final row = await _client
        .from('menus')
        .update({
          'name': name.trim(),
          'description': description.trim(),
          'price': price,
          'is_active': isActive,
          'image_path': imagePath,
        })
        .eq('id', id)
        .select('*')
        .single();

    return MenuItem.fromJson(
      row,
      resolvedImageUrl: resolveImageUrl(row['image_path'] as String?),
    );
  }

  /// Soft delete: keeps historical order_items intact while hiding menu from active catalog
  Future<void> softDeleteMenu(String id) async {
    await _client.from('menus').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': false,
    }).eq('id', id);
  }

  Future<void> restoreMenu(String id) async {
    await _client.from('menus').update({
      'deleted_at': null,
      'is_active': true,
    }).eq('id', id);
  }

  Future<void> toggleMenuActive(String id, bool isActive) async {
    await _client
        .from('menus')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}
