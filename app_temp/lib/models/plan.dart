/// 套餐数据模型
class Plan {

  /// 安全地将 dynamic 值转为 int
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  /// 安全地将 dynamic 值转为 double
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

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

  bool get isRecommended => badge != null && badge!.isNotEmpty;

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      originalPrice: _toDouble(json['originalPrice']),
      days: _toInt(json['days']),
      credits: _toInt(json['credits']),
      badge: json['badge']?.toString(),
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
