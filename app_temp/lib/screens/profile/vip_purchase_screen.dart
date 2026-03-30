import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// VIP 购买页面
class VipPurchaseScreen extends StatefulWidget {
  const VipPurchaseScreen({super.key});

  @override
  State<VipPurchaseScreen> createState() => _VipPurchaseScreenState();
}

class _VipPurchaseScreenState extends State<VipPurchaseScreen> {
  int _selectedPlan = 1; // 0: weekly, 1: monthly, 2: yearly

  static const _plans = [
    _Plan(name: 'Weekly', price: '\$2.99', save: ''),
    _Plan(name: 'Monthly', price: '\$9.99', save: 'Most Popular'),
    _Plan(name: 'Yearly', price: '\$59.99', save: 'Save 50%'),
  ];

  @override
  Widget build(BuildContext context) {
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
            // Hero
            _buildHero(),
            // Features
            _buildFeatures(),
            // Plans
            _buildPlans(),
            // Subscribe button
            _buildSubscribe(),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
          Row(
            children: List.generate(3, (i) {
              final plan = _plans[i];
              final isSelected = _selectedPlan == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPlan = i),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: i == 0 ? 0 : 5,
                      right: i == 2 ? 0 : 5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : context.appColors.surfaceBackground,
                        width: 1.5,
                      ),
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.15)
                          : context.appColors.cardBackground,
                    ),
                    child: Column(
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.price,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (plan.save.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            plan.save,
                            style: TextStyle(
                              color: isSelected
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

  Widget _buildSubscribe() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscribe feature coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
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
}

class _Plan {
  final String name;
  final String price;
  final String save;
  const _Plan({required this.name, required this.price, required this.save});
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  final Color bgColor;
  final Color iconColor;
  const _Feature(this.icon, this.title, this.desc, this.bgColor, this.iconColor);
}
