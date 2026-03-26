/// 用户数据模型
class User {
  final String id;
  final String? nickname;
  final String? avatar;
  final String? phone;
  final int? vipLevel;
  final DateTime? vipExpireAt;
  final int? remainCredits;
  final int? totalGenerations;

  User({
    required this.id,
    this.nickname,
    this.avatar,
    this.phone,
    this.vipLevel,
    this.vipExpireAt,
    this.remainCredits,
    this.totalGenerations,
  });

  /// 是否为VIP用户
  bool get isVip => (vipLevel ?? 0) > 0 &&
      (vipExpireAt == null || vipExpireAt!.isAfter(DateTime.now()));

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname'],
      avatar: json['avatar'],
      phone: json['phone'],
      vipLevel: json['vipLevel'] is int
          ? json['vipLevel']
          : int.tryParse(json['vipLevel']?.toString() ?? '0'),
      vipExpireAt: json['vipExpireAt'] != null
          ? DateTime.tryParse(json['vipExpireAt'].toString())
          : null,
      remainCredits: json['remainCredits'] is int
          ? json['remainCredits']
          : int.tryParse(json['remainCredits']?.toString() ?? '0'),
      totalGenerations: json['totalGenerations'] is int
          ? json['totalGenerations']
          : int.tryParse(json['totalGenerations']?.toString() ?? '0'),
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
    };
  }
}
