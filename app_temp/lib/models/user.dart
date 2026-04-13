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

  /// 后端直接返回的 isVip（与 subscription_* 并存时优先参考）
  final bool isVipServerHint;

  /// 订阅层级：free / weekly / monthly / yearly
  final String subscriptionTier;

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
    this.isVipServerHint = false,
    this.subscriptionTier = 'free',
  });

  /// 是否为VIP用户
  bool get isVip =>
      isVipServerHint ||
      (vipLevel ?? 0) > 0 ||
      (vipExpireAt != null && vipExpireAt!.isAfter(DateTime.now()));

  /// 会员级别显示名称
  String get tierDisplayName {
    switch (subscriptionTier) {
      case 'weekly':
        return 'Weekly VIP';
      case 'monthly':
        return 'Monthly VIP';
      case 'yearly':
        return 'Annual VIP';
      case 'lifetime':
        return 'Lifetime VIP';
      default:
        return isVip ? 'VIP Member' : 'Free Plan';
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final tier = json['subscription_tier']?.toString();
    final vipFromTier = tier != null && tier != 'free' && tier.isNotEmpty;
    final expireAt = json['vipExpireAt'] != null
        ? DateTime.tryParse(json['vipExpireAt'].toString())
        : (json['subscription_expires_at'] != null
            ? DateTime.tryParse(json['subscription_expires_at'].toString())
            : null);
    final rawVipLevel = _toInt(json['vipLevel']);
    return User(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      avatar: json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      vipLevel: rawVipLevel > 0 ? rawVipLevel : (vipFromTier ? 1 : 0),
      vipExpireAt: expireAt,
      remainCredits: _toInt(json['remainCredits'] ?? json['remaining']),
      totalGenerations: _toInt(json['totalGenerations'] ?? json['total_generated']),
      autoSave: _toBool(json['auto_save'] ?? 1),
      theme: json['theme']?.toString() ?? 'dark',
      isVipServerHint: json['isVip'] == true,
      subscriptionTier: tier ?? 'free',
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
