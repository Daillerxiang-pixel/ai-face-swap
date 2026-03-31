/// 模板数据模型
class Template {

  /// 安全地将 dynamic 值转为 bool（兼容 SQLite 的 0/1）
  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return false;
  }

  /// 安全地将 dynamic 值转为 int
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  /// 将后端 type 字段归一化（兼容中文）
  /// "图片" / "image" → "image"，"视频" / "video" → "video"
  static String _normalizeType(dynamic value) {
    final str = value?.toString().trim().toLowerCase() ?? '';
    if (str == 'image' || str == '图片') return 'image';
    if (str == 'video' || str == '视频') return 'video';
    return str.isEmpty ? 'image' : str; // 默认按图片处理
  }

  /// 是否为视频模板
  bool get isVideo => type == 'video';

  final String id;
  final String name;
  final String? cover;
  final String? preview;
  final String? previewUrl;
  final String? videoUrl;
  final String? category;
  final String? scene;
  final String? type;
  final int? useCount;
  final bool? isFavorite;
  final String? description;
  final String? icon;
  final String? bg;
  final String? usage;
  final int? usageNum;
  final String? badge;
  final double? rating;
  final String? provider;
  final DateTime? createdAt;

  Template({
    required this.id,
    required this.name,
    this.cover,
    this.preview,
    this.previewUrl,
    this.videoUrl,
    this.category,
    this.scene,
    this.type,
    this.useCount,
    this.isFavorite,
    this.description,
    this.icon,
    this.bg,
    this.usage,
    this.usageNum,
    this.badge,
    this.rating,
    this.provider,
    this.createdAt,
  });

  /// 获取显示用图片URL（优先 previewUrl）
  String get displayUrl => previewUrl ?? preview ?? cover ?? '';

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      cover: json['cover'],
      preview: json['preview'],
      previewUrl: json['previewUrl'] ?? json['preview_url'],
      videoUrl: json['videoUrl'] ?? json['video_url'],
      category: json['category'],
      scene: json['scene'],
      type: _normalizeType(json['type']),
      useCount: _toInt(json['useCount'] ?? json['usageNum'] ?? json['usage_count']),
      isFavorite: _toBool(json['isFavorite'] ?? json['is_favourite']),
      description: json['description'] ?? json['desc'],
      icon: json['icon'],
      bg: json['bg'] ?? json['bg_gradient'],
      usage: json['usage']?.toString(),
      usageNum: _toInt(json['usageNum']),
      badge: json['badge']?.toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      provider: json['provider']?.toString(),
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
      'previewUrl': previewUrl,
      'videoUrl': videoUrl,
      'category': category,
      'scene': scene,
      'type': type,
      'useCount': useCount,
      'isFavorite': isFavorite,
      'description': description,
      'icon': icon,
      'bg': bg,
      'usage': usage,
      'usageNum': usageNum,
      'badge': badge,
      'rating': rating,
      'provider': provider,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Template copyWith({
    String? id,
    String? name,
    String? cover,
    String? preview,
    String? previewUrl,
    String? videoUrl,
    String? category,
    String? scene,
    String? type,
    int? useCount,
    bool? isFavorite,
    String? description,
    String? icon,
    String? bg,
    String? usage,
    int? usageNum,
    String? badge,
    double? rating,
    String? provider,
    DateTime? createdAt,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      preview: preview ?? this.preview,
      previewUrl: previewUrl ?? this.previewUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      category: category ?? this.category,
      scene: scene ?? this.scene,
      type: type ?? this.type,
      useCount: useCount ?? this.useCount,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      bg: bg ?? this.bg,
      usage: usage ?? this.usage,
      usageNum: usageNum ?? this.usageNum,
      badge: badge ?? this.badge,
      rating: rating ?? this.rating,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
