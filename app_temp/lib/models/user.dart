/// 用户数据模型
class User {

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

  final String id;
  final String? nickname;
  final String? avatar;
  final String? phone;
  final int? vipLevel;
  final DateTime? vipExpireAt;
  final int? remainCredits;
  final int? totalGenerations;
  final bool autoSave;
  final String theme;

  User({
    required this.id,
    this.nickname,
    this.avatar,
    this.phone,
    this.vipLevel,
    this.vipExpireAt,
    this.remainCredits,
    this.totalGenerations,
    this.autoSave = true,
    this.theme = 'dark',
  });

  /// 是否为VIP用户
  bool get isVip => (vipLevel ?? 0) > 0 ||
      (vipExpireAt != null && vipExpireAt!.isAfter(DateTime.now()));

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      avatar: json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      vipLevel: _toInt(json['vipLevel']),
      vipExpireAt: json['vipExpireAt'] != null
          ? DateTime.tryParse(json['vipExpireAt'].toString())
          : null,
      remainCredits: _toInt(json['remainCredits'] ?? json['remaining']),
      totalGenerations: _toInt(json['totalGenerations'] ?? json['total_generated']),
      autoSave: _toBool(json['auto_save'] ?? 1),
      theme: json['theme']?.toString() ?? 'dark',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
      'vipLevel': vipLevel,
      'vipExpireAt': vipExpireAt?.toIso8601String(),
      'remainCredits': remainCredits,
      'totalGenerations': totalGenerations,
      'auto_save': autoSave ? 1 : 0,
      'theme': theme,
    };
  }
}
