import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/recharge_plan.dart';
import '../../services/api_service.dart';
import '../../services/subscription_service.dart';

/// VIP 购买页面（套餐文案与标价来自服务端 `/api/plans`，支付仍走 App Store IAP）
class VipPurchaseScreen extends StatefulWidget {
  const VipPurchaseScreen({super.key});

  @override
  State<VipPurchaseScreen> createState() => _VipPurchaseScreenState();
}

class _VipPurchaseScreenState extends State<VipPurchaseScreen> {
  int _selectedPlan = 1;
  SubscriptionStatus _lastStatus = SubscriptionStatus.unknown;

  List<RechargePlan>? _serverPlans;
  bool _plansLoading = true;
  String? _plansError;

  /// 与 Flyway 种子一致，接口失败时兜底展示
  static final List<RechargePlan> _kFallbackPlans = [
    RechargePlan(
      id: 0,
      name: '周会员',
      priceWeekly: 9.99,
      priceMonthly: 0,
      priceYearly: 0,
      monthlyLimit: 80,
      featureLines: const [],
      sortOrder: 1,
    ),
    RechargePlan(
      id: 0,
      name: '月会员',
      priceWeekly: 0,
      priceMonthly: 39.99,
      priceYearly: 0,
      monthlyLimit: 200,
      featureLines: const [],
      sortOrder: 2,
    ),
    RechargePlan(
      id: 0,
      name: '年会员',
      priceWeekly: 0,
      priceMonthly: 0,
      priceYearly: 99.99,
      monthlyLimit: 300,
      featureLines: const [],
      sortOrder: 3,
    ),
  ];

  List<RechargePlan> get _effectivePlans =>
      (_serverPlans != null && _serverPlans!.isNotEmpty) ? _serverPlans! : _kFallbackPlans;

  @override
  void initState() {
    super.initState();
    _loadServerPlans();
  }

  Future<void> _loadServerPlans() async {
    setState(() {
      _plansLoading = true;
      _plansError = null;
    });
    final res = await ApiService().getRechargePlans();
    if (!mounted) return;
    if (res.success && res.data != null && res.data!.isNotEmpty) {
      final list = res.data!;
      setState(() {
        _serverPlans = list;
        _plansLoading = false;
        if (_selectedPlan >= list.length) {
          _selectedPlan = list.length > 1 ? 1 : 0;
        }
      });
    } else {
      setState(() {
        _plansLoading = false;
        _plansError = res.message ?? 'Failed to load plans';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, iap, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (iap.status != _lastStatus) {
            if (iap.status == SubscriptionStatus.active) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Subscription activated!'),
                  backgroundColor: Color(0xFF34C759),
                ),
              );
            }
            _lastStatus = iap.status;
          }
          if (iap.errorMessage != null && !iap.isPurchasing) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Purchase failed: ${iap.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });

        return Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: AppTheme.primary, size: 28),
                  SizedBox(width: 0),
                  Text('Back', style: TextStyle(color: AppTheme.primary, fontSize: 17)),
                ],
              ),
            ),
            backgroundColor: context.appColors.background,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(),
                _buildFeatures(),
                _buildPlans(iap),
                _buildSubscribe(iap),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A2D7A), Color(0xFF2D1B4E), Color(0xFF1a1035)],
        ),
      ),
      child: Column(
        children: [
          const Text('👑', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'Unlock Premium',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get unlimited access to all features',
            style: TextStyle(
              color: context.appColors.textSecondary.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    const features = [
      _Feature(Icons.all_inclusive_outlined, 'Unlimited Swaps', 'No daily limits on face swaps', Colors.purple, AppTheme.primary),
      _Feature(Icons.hd_outlined, 'HD Quality', 'Export results in full HD resolution', Colors.orange, const Color(0xFFF59E0B)),
      _Feature(Icons.water_drop_outlined, 'No Watermark', 'Remove AI FaceSwap watermark', Colors.purple, AppTheme.primary),
      _Feature(Icons.bolt_outlined, 'Priority Processing', 'Faster AI generation queue', Colors.green, const Color(0xFF34C759)),
      _Feature(Icons.auto_awesome_outlined, 'Exclusive Templates', 'Access premium member-only templates', Colors.orange, const Color(0xFFF59E0B)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VIP Features',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: f.bgColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.icon, color: f.iconColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.desc,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPlans(SubscriptionService iap) {
    final plans = _effectivePlans;
    final iapLoading = iap.isLoading && iap.products.isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Plan',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_plansError != null && (_serverPlans == null || _serverPlans!.isEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Using offline prices ($_plansError)',
                style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          if (_plansLoading && (_serverPlans == null || _serverPlans!.isEmpty))
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (iapLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(plans.length, (i) {
                final cfg = plans[i];
                final productId = cfg.iapProductId;
                final store = iap.products[productId];
                final isSelected = _selectedPlan == i;
                final isYearly = cfg.priceYearly > 0;

                final name = cfg.name.isNotEmpty ? cfg.name : (store?.displayName ?? '');
                final price = store?.price ?? cfg.referencePriceLabel;
                final badgeFromServer = cfg.badgeForIndex(i, plans.length);
                final badge = badgeFromServer.isNotEmpty
                    ? badgeFromServer
                    : (store?.badge ?? '');

                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 50) / 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPlan = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : context.appColors.surfaceBackground,
                          width: 1.5,
                        ),
                        color: isYearly
                            ? const Color(0xFFF59E0B).withOpacity(0.1)
                            : isSelected
                                ? AppTheme.primary.withOpacity(0.15)
                                : context.appColors.cardBackground,
                      ),
                      child: Column(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            price,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            cfg.periodHint,
                            style: const TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                          if (badge.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              badge,
                              style: TextStyle(
                                color: isYearly
                                    ? const Color(0xFFF59E0B)
                                    : isSelected
                                        ? AppTheme.primary
                                        : const Color(0xFF34C759),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscribe(SubscriptionService iap) {
    final isPurchasing = iap.isPurchasing;
    final isSubscribed = iap.status == SubscriptionStatus.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isPurchasing || isSubscribed ? null : () => _handleSubscribe(iap),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFF59E0B).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: isPurchasing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : isSubscribed
                      ? const Text(
                          '✓ Subscribed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        )
                      : const Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _handleRestore(iap),
            child: Text(
              'Restore Purchases',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Auto-renews. Cancel anytime in settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscribe(SubscriptionService iap) async {
    final plans = _effectivePlans;
    if (plans.isEmpty || _selectedPlan >= plans.length) return;
    final productId = plans[_selectedPlan].iapProductId;
    await iap.purchase(productId);
  }

  Future<void> _handleRestore(SubscriptionService iap) async {
    await iap.restorePurchases();
    if (!iap.isPurchasing && iap.status != SubscriptionStatus.active) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found'),
          ),
        );
      }
    }
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  final Color bgColor;
  final Color iconColor;
  const _Feature(this.icon, this.title, this.desc, this.bgColor, this.iconColor);
}
