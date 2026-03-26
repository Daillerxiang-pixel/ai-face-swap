/// 模板数据模型
class Template {
  final String id;
  final String name;
  final String? cover;
  final String? preview;
  final String? category;
  final String? scene;
  final int? useCount;
  final bool? isFavorite;
  final String? description;
  final DateTime? createdAt;

  Template({
    required this.id,
    required this.name,
    this.cover,
    this.preview,
    this.category,
    this.scene,
    this.useCount,
    this.isFavorite,
    this.description,
    this.createdAt,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      cover: json['cover'],
      preview: json['preview'],
      category: json['category'],
      scene: json['scene'],
      useCount: json['useCount'] is int
          ? json['useCount']
          : int.tryParse(json['useCount']?.toString() ?? '0'),
      isFavorite: json['isFavorite'] ?? json['is_favourite'] ?? false,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover': cover,
      'preview': preview,
      'category': category,
      'scene': scene,
      'useCount': useCount,
      'isFavorite': isFavorite,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
