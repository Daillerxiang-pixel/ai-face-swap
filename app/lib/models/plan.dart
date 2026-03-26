/// 套餐数据模型
class Plan {
  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final int days;
  final int credits;
  final String? badge;

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.days,
    required this.credits,
    this.badge,
  });

  /// 是否为推荐套餐
  bool get isRecommended => badge != null && badge!.isNotEmpty;

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      days: json['days'] is int
          ? json['days']
          : int.tryParse(json['days']?.toString() ?? '0') ?? 0,
      credits: json['credits'] is int
          ? json['credits']
          : int.tryParse(json['credits']?.toString() ?? '0') ?? 0,
      badge: json['badge'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'days': days,
      'credits': credits,
      'badge': badge,
    };
  }
}
