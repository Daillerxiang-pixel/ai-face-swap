import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'api_service.dart';

/// 订阅套餐 / 商店商品 ID（iOS 为 App Store Connect ID）
class SubscriptionProducts {
  SubscriptionProducts._();

  /// App Store：周 / 月 / 年（与后台 plans.apple_product_id、验单 PRODUCT_MAP 一致）
  static const String weeklyApple = '10001';
  static const String monthlyApple = '10002';
  static const String yearlyApple = '10003';

  static const List<String> appleStoreIds = [weeklyApple, monthlyApple, yearlyApple];

  /// Google Play 占位（未配置前与旧 ID 对齐，需后台与 Play Console 一致后替换）
  static const String weeklyAndroid = 'face_swap_weekly';
  static const String monthlyAndroid = 'face_swap_monthly';
  static const String yearlyAndroid = 'face_swap_yearly';

  static const List<String> androidStoreIds = [weeklyAndroid, monthlyAndroid, yearlyAndroid];
}

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
  /// 原始价格数值，如 19.99
  final double rawPrice;
  final String currencyCode;
  final String currencySymbol;
  final ProductDetails productDetails;

  SubscriptionPlanInfo({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    required this.productDetails,
  });

  /// 套餐名称
  String get displayName {
    switch (productId) {
      case SubscriptionProducts.weeklyApple:
      case SubscriptionProducts.weeklyAndroid:
        return 'Weekly Plan';
      case SubscriptionProducts.monthlyApple:
      case SubscriptionProducts.monthlyAndroid:
        return 'Monthly Plan';
      case SubscriptionProducts.yearlyApple:
      case SubscriptionProducts.yearlyAndroid:
        return 'Annual Plan';
      default:
        return title;
    }
  }

  /// 标签文案
  String? get badge {
    switch (productId) {
      case SubscriptionProducts.monthlyApple:
      case SubscriptionProducts.monthlyAndroid:
        return 'Most Popular';
      case SubscriptionProducts.yearlyApple:
      case SubscriptionProducts.yearlyAndroid:
        return 'Best Value';
      default:
        return null;
    }
  }
}

/// Apple IAP 订阅服务
class SubscriptionService with ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final ApiService _api = ApiService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 产品列表
  final Map<String, SubscriptionPlanInfo> _products = {};

  /// StoreKit 是否可用（缓存）
  bool? _storeAvailable;

  /// 当前订阅状态
  SubscriptionStatus _status = SubscriptionStatus.unknown;

  /// 是否正在加载
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  /// 购买中标识
  bool _isPurchasing = false;

  Map<String, SubscriptionPlanInfo> get products => _products;
  SubscriptionStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPurchasing => _isPurchasing;
  bool get isAvailable => _storeAvailable ?? false;

  SubscriptionPlanInfo? get weeklyApple => _products[SubscriptionProducts.weeklyApple];
  SubscriptionPlanInfo? get monthlyApple => _products[SubscriptionProducts.monthlyApple];
  SubscriptionPlanInfo? get yearlyApple => _products[SubscriptionProducts.yearlyApple];

  /// 初始化：加载产品 + 监听购买更新
  Future<void> initialize() async {
    debugPrint('[IAP] initialize() called, platform=${Platform.operatingSystem}');

    if (!Platform.isIOS && !Platform.isAndroid) {
      _storeAvailable = false;
      _status = SubscriptionStatus.notSubscribed;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _storeAvailable = await _iap.isAvailable();
      debugPrint('[IAP] Store available: $_storeAvailable');
      if (_storeAvailable != true) {
        debugPrint('[IAP] StoreKit not available — check IAP capability in Xcode and App Store Connect');
        _status = SubscriptionStatus.notSubscribed;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 监听购买状态变化
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription = null,
        onError: (error) {
          debugPrint('[IAP] Purchase stream error: $error');
          _errorMessage = 'Purchase stream error: $error';
          notifyListeners();
        },
      );

      // 加载产品信息
      await _loadProducts();
      debugPrint('[IAP] Products loaded: ${_products.keys.toList()}');

      // 恢复已有购买
      await restorePurchases();
    } catch (e, st) {
      debugPrint('[IAP] Initialization failed: $e\n$st');
      _errorMessage = 'Initialization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Set<String> get _storeProductIds {
    if (Platform.isIOS) {
      return SubscriptionProducts.appleStoreIds.toSet();
    }
    return SubscriptionProducts.androidStoreIds.toSet();
  }

  /// 从应用商店加载产品信息（iOS 仅查询 App Store 商品 ID）
  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_storeProductIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IAP] Products not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      _errorMessage = 'Failed to load products: ${response.error}';
      notifyListeners();
      return;
    }

    _products.clear();
    for (final detail in response.productDetails) {
      _products[detail.id] = SubscriptionPlanInfo(
        productId: detail.id,
        title: detail.title,
        description: detail.description,
        price: detail.price,
        rawPrice: detail.rawPrice,
        currencyCode: detail.currencyCode,
        currencySymbol: detail.currencySymbol,
        productDetails: detail,
      );
    }
    notifyListeners();
  }

  /// 处理购买状态更新
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('[IAP] Purchase pending: ${purchaseDetails.productID}');
          _isPurchasing = true;
          _errorMessage = null;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          debugPrint('[IAP] Purchase successful: ${purchaseDetails.productID} (status: ${purchaseDetails.status})');

          final success = await _verifyReceipt(purchaseDetails);

          if (success) {
            _status = SubscriptionStatus.active;
            _errorMessage = null;
          } else {
            _errorMessage = 'Receipt verification failed';
          }

          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }

          _isPurchasing = false;
          notifyListeners();
          break;

        case PurchaseStatus.error:
          debugPrint('[IAP] Purchase error: ${purchaseDetails.error}');
          _errorMessage = purchaseDetails.error?.message ?? 'Purchase failed';
          _isPurchasing = false;
          notifyListeners();
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('[IAP] Purchase canceled: ${purchaseDetails.productID}');
          _isPurchasing = false;
          _errorMessage = null;
          notifyListeners();
          break;
      }
    }
  }

  /// 购买订阅（非消耗品 / 订阅）
  Future<bool> purchase(String productId) async {
    if (_storeAvailable != true) {
      _errorMessage = 'In-App Purchase is not available';
      notifyListeners();
      return false;
    }

    final plan = _products[productId];
    if (plan == null) {
      _errorMessage = 'Product not found: $productId. Please check your network and try again.';
      debugPrint('[IAP] Product "$productId" not in loaded products: ${_products.keys.toList()}');
      notifyListeners();
      return false;
    }

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: plan.productDetails);
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        _errorMessage = 'Failed to initiate purchase';
        _isPurchasing = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Purchase error: $e';
      _isPurchasing = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 恢复购买
  Future<void> restorePurchases() async {
    if (_storeAvailable != true) {
      _errorMessage = 'In-App Purchase is not available';
      return;
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = 'Restore failed: $e';
    }
  }

  /// 将 receipt 发送到后端验证
  Future<bool> _verifyReceipt(PurchaseDetails purchaseDetails) async {
    try {
      // iOS: localVerificationData = base64-encoded App Store receipt
      final receiptData = purchaseDetails.verificationData.localVerificationData;

      final response = await _api.verifySubscription(
        productId: purchaseDetails.productID,
        receiptData: receiptData,
        transactionId: purchaseDetails.purchaseID ?? '',
      );

      return response.success == true;
    } catch (e) {
      debugPrint('[IAP] Receipt verification error: $e');
      return false;
    }
  }

  /// 刷新订阅状态（从后端获取）
  Future<void> refreshStatus() async {
    try {
      final response = await _api.getSubscriptionStatus();
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final isActive = data['isActive'] == true;
        _status = isActive ? SubscriptionStatus.active : SubscriptionStatus.notSubscribed;
      }
    } catch (_) {
      // 网络失败时保持当前状态
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
