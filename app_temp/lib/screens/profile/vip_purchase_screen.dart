import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/subscription_service.dart';

/// VIP 购买页面
class VipPurchaseScreen extends StatefulWidget {
  const VipPurchaseScreen({super.key});

  @override
  State<VipPurchaseScreen> createState() => _VipPurchaseScreenState();
}

class _VipPurchaseScreenState extends State<VipPurchaseScreen> {
  int _selectedPlan = 1; // 0: weekly, 1: monthly, 2: yearly
  SubscriptionStatus _lastStatus = SubscriptionStatus.unknown;

  static const _planIds = [
    SubscriptionProducts.weekly,
    SubscriptionProducts.monthly,
    SubscriptionProducts.yearly,
    SubscriptionProducts.lifetime,
  ];

  static const _fallbackPlans = [
    _FallbackPlan(name: 'Weekly', price: '\$19.99', badge: ''),
    _FallbackPlan(name: 'Monthly', price: '\$69.99', badge: 'Most Popular'),
    _FallbackPlan(name: 'Yearly', price: '\$399.99', badge: 'Best Value'),
    _FallbackPlan(name: 'Lifetime', price: '\$0.99', badge: 'One-time'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, iap, _) {
        // 监听状态变化弹出通知
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
            _buildPlans(),
            _buildSubscribe(),
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

  Widget _buildPlans() {
    return Builder(
      builder: (context) {
        final iap = context.read<SubscriptionService>();
        final isLoading = iap.isLoading && iap.products.isEmpty;

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
              const SizedBox(height: 12),
              if (isLoading)
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
                  children: List.generate(4, (i) {
                    final productId = _planIds[i];
                    final plan = iap.products[productId];
                    final fallback = _fallbackPlans[i];
                    final isSelected = _selectedPlan == i;
                    final isLifetime = productId == SubscriptionProducts.lifetime;

                    final name = plan?.displayName ?? fallback.name;
                    final price = plan?.price ?? fallback.price;
                    final badge = plan?.badge ?? fallback.badge;

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
                            color: isLifetime
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
                              if (badge.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  badge,
                                  style: TextStyle(
                                    color: isLifetime
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
      },
    );
  }

  Widget _buildSubscribe() {
    return Builder(
      builder: (context) {
        final iap = context.watch<SubscriptionService>();
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
                  onPressed: isPurchasing || isSubscribed
                      ? null
                      : () => _handleSubscribe(iap),
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
      },
    );
  }

  Future<void> _handleSubscribe(SubscriptionService iap) async {
    final productId = _planIds[_selectedPlan];
    await iap.purchase(productId);

    // 购买完成后检查结果（购买是异步的，结果通过 purchaseStream 回调）
    // 这里不需要立即检查，因为 purchaseStream 会更新状态
  }

  Future<void> _handleRestore(SubscriptionService iap) async {
    await iap.restorePurchases();
    // restorePurchases 结果通过 purchaseStream 回调
    // 如果之前有购买，purchaseStream 会触发 restored 状态
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

class _FallbackPlan {
  final String name;
  final String price;
  final String badge;
  const _FallbackPlan({required this.name, required this.price, required this.badge});
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  final Color bgColor;
  final Color iconColor;
  const _Feature(this.icon, this.title, this.desc, this.bgColor, this.iconColor);
}
