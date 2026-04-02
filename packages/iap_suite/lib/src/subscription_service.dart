import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'subscription_models.dart';

/// Receipt 验证回调 —— 由调用方注入具体 API 逻辑
typedef ReceiptVerifier = Future<bool> Function({
  required String productId,
  required String receiptData,
  required String transactionId,
});

/// 通用 In-App Purchase 订阅服务
///
/// 不依赖具体的 API 层，通过 [ReceiptVerifier] 回调将 receipt 验证
/// 逻辑交给宿主项目。
class SubscriptionService with ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final ReceiptVerifier _verifyReceipt;

  /// 要加载的产品 ID 列表
  final List<String> productIds;

  /// 产品 ID → 显示名称 映射
  final Map<String, String> displayNameMap;

  /// 产品 ID → badge 标签 映射
  final Map<String, String?> badgeMap;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final Map<String, SubscriptionPlanInfo> _products = {};
  bool? _storeAvailable;
  SubscriptionStatus _status = SubscriptionStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPurchasing = false;

  // ─── Getters ──────────────────────────────────────

  Map<String, SubscriptionPlanInfo> get products => _products;
  SubscriptionStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPurchasing => _isPurchasing;
  bool get isAvailable => _storeAvailable ?? false;

  SubscriptionPlanInfo? getPlan(String id) => _products[id];

  // ─── Constructor ──────────────────────────────────

  SubscriptionService({
    required this.productIds,
    required ReceiptVerifier verifyReceipt,
    this.displayNameMap = const {},
    this.badgeMap = const {},
  }) : _verifyReceipt = verifyReceipt;

  // ─── Lifecycle ────────────────────────────────────

  /// 初始化：检查 StoreKit 可用性 → 加载产品 → 监听购买流 → 恢复购买
  Future<void> initialize() async {
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
      if (!_storeAvailable!) {
        _status = SubscriptionStatus.notSubscribed;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription = null,
        onError: (error) {
          _errorMessage = 'Purchase stream error: $error';
          notifyListeners();
        },
      );

      await _loadProducts();
      await restorePurchases();
    } catch (e) {
      _errorMessage = 'Initialization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Public Methods ──────────────────────────────

  /// 购买商品
  Future<bool> purchase(String productId) async {
    if (!_storeAvailable!) {
      _errorMessage = 'In-App Purchase is not available';
      notifyListeners();
      return false;
    }

    final plan = _products[productId];
    if (plan == null) {
      _errorMessage = 'Product not found: $productId';
      notifyListeners();
      return false;
    }

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(
        productDetails: plan.rawProductDetails as ProductDetails,
      );
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

  /// 恢复购买
  Future<void> restorePurchases() async {
    if (!_storeAvailable!) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = 'Restore failed: $e';
    }
  }

  /// 手动设置订阅状态（从后端同步后调用）
  void setStatus(SubscriptionStatus status) {
    _status = status;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Private Methods ─────────────────────────────

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(productIds.toSet());

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
        displayName: displayNameMap[detail.id] ?? detail.id,
        badge: badgeMap[detail.id],
        rawProductDetails: detail,
      );
    }
    notifyListeners();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> list) async {
    for (final pd in list) {
      switch (pd.status) {
        case PurchaseStatus.pending:
          _isPurchasing = true;
          notifyListeners();

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _verifyReceipt(
            productId: pd.productID,
            receiptData: pd.verificationData.localVerificationData,
            transactionId: pd.purchaseID ?? '',
          );
          if (ok) {
            _status = SubscriptionStatus.active;
          } else {
            _errorMessage = 'Receipt verification failed';
          }
          if (pd.pendingCompletePurchase) {
            await _iap.completePurchase(pd);
          }

        case PurchaseStatus.error:
          _errorMessage = pd.error?.message ?? 'Purchase failed';
          _isPurchasing = false;
          notifyListeners();
          if (pd.pendingCompletePurchase) {
            await _iap.completePurchase(pd);
          }

        case PurchaseStatus.canceled:
          _isPurchasing = false;
          notifyListeners();
      }
    }
    _isPurchasing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
