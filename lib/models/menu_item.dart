class MenuItem {
  final String id;
  final String name;
  final String? imagePath;
  final String? imageUrl;
  final String description;
  final int price;
  final bool isActive;
  final DateTime? deletedAt;
  final DateTime updatedAt;

  const MenuItem({
    required this.id,
    required this.name,
    this.imagePath,
    this.imageUrl,
    required this.description,
    required this.price,
    required this.isActive,
    this.deletedAt,
    required this.updatedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory MenuItem.fromJson(
    Map<String, dynamic> json, {
    String? resolvedImageUrl,
  }) {
    return MenuItem(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      imagePath: json['image_path'] as String?,
      imageUrl: resolvedImageUrl,
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num).toInt(),
      isActive: (json['is_active'] as bool?) ?? true,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
