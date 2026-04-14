import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// 服务端 `/api/plans` 返回的充值档位。
/// iOS IAP 使用 [appleProductId]（须与 App Store Connect 一致）。
class RechargePlan {
  final int id;
  final String name;
  /// App Store Connect 商品 ID（如 10001）
  final String? appleProductId;
  final double priceWeekly;
  final double priceMonthly;
  final double priceYearly;
  final int monthlyLimit;
  final List<String> featureLines;
  final int sortOrder;

  const RechargePlan({
    required this.id,
    required this.name,
    this.appleProductId,
    required this.priceWeekly,
    required this.priceMonthly,
    required this.priceYearly,
    required this.monthlyLimit,
    required this.featureLines,
    required this.sortOrder,
  });

  factory RechargePlan.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['features'];
    List<String> lines = const [];
    if (featuresRaw is List) {
      lines = featuresRaw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    } else if (featuresRaw is String && featuresRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(featuresRaw);
        if (decoded is List) {
          lines = decoded.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {}
    }

    double toD(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    final apRaw = json['apple_product_id']?.toString().trim();
    return RechargePlan(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      appleProductId: (apRaw != null && apRaw.isNotEmpty) ? apRaw : null,
      priceWeekly: toD(json['price_weekly']),
      priceMonthly: toD(json['price_monthly']),
      priceYearly: toD(json['price_yearly']),
      monthlyLimit: (json['monthly_limit'] is num)
          ? (json['monthly_limit'] as num).toInt()
          : int.tryParse('${json['monthly_limit']}') ?? 0,
      featureLines: lines,
      sortOrder: (json['sort_order'] is num)
          ? (json['sort_order'] as num).toInt()
          : int.tryParse('${json['sort_order']}') ?? 0,
    );
  }

  /// 当前平台用于商店查询 / 购买的商品 ID。
  String get iapProductId {
    final apple = appleProductId?.trim();
    if (!kIsWeb && apple != null && apple.isNotEmpty) {
      try {
        if (Platform.isIOS) return apple;
      } catch (_) {}
    }
    if (priceWeekly > 0) return 'face_swap_weekly';
    if (priceMonthly > 0) return 'face_swap_monthly';
    if (priceYearly > 0) return 'face_swap_yearly';
    return 'face_swap_monthly';
  }

  /// Fallback price label when the store price is not yet loaded (English UI).
  String get referencePriceLabel {
    if (priceWeekly > 0) return '\$${priceWeekly.toStringAsFixed(2)}';
    if (priceMonthly > 0) return '\$${priceMonthly.toStringAsFixed(2)}';
    if (priceYearly > 0) return '\$${priceYearly.toStringAsFixed(2)}';
    return '—';
  }

  String get periodHint {
    if (priceWeekly > 0) return '/wk';
    if (priceMonthly > 0) return '/mo';
    if (priceYearly > 0) return '/yr';
    return '';
  }

  String badgeForIndex(int index, int total) {
    if (total <= 1) return '';
    if (index == 1) return 'Most Popular';
    if (index == total - 1 && priceYearly > 0) return 'Best Value';
    return '';
  }
}
