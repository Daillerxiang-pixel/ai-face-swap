/// 订阅状态
enum SubscriptionStatus {
  unknown,
  notSubscribed,
  active,
  expired,
  inGracePeriod,
  inBillingRetryPeriod,
}

/// 单个套餐信息
class SubscriptionPlanInfo {
  final String productId;
  final String title;
  final String description;
  /// 格式化价格，如 "$19.99"
  final String price;
  /// 原始价格数值
  final double rawPrice;
  final String currencyCode;
  final String currencySymbol;
  /// 套餐显示名称（可由子类或项目覆盖）
  final String displayName;
  /// 推荐标签
  final String? badge;

  /// 原始 SDK ProductDetails（内部使用，不暴露）
  final dynamic _rawProductDetails;

  SubscriptionPlanInfo({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    this.displayName = '',
    this.badge,
    required dynamic rawProductDetails,
  }) : _rawProductDetails = rawProductDetails;

  /// 获取原始 ProductDetails（仅限 iap_suite 内部使用）
  dynamic get rawProductDetails => _rawProductDetails;
}
