import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/subscription_service.dart';
import 'vip_purchase_screen.dart';

/// VIP 中心页面 - 显示当前订阅状态
class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化时刷新订阅状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionService>().refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text(
          'VIP Center',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: context.appColors.background,
        elevation: 0,
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, iap, _) {
          final isActive = iap.status == SubscriptionStatus.active;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态卡片
                _buildStatusCard(isActive),
                const SizedBox(height: 24),

                // VIP 权益列表
                _buildBenefits(),
                const SizedBox(height: 24),

                // 管理订阅
                if (isActive) ...[
                  _buildManageButton(),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildSubscribeButton(),
                  const SizedBox(height: 16),
                  _buildRestoreButton(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isActive
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.appColors.cardBackground,
                  context.appColors.surfaceBackground,
                ],
              ),
      ),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.verified : Icons.diamond_outlined,
            size: 48,
            color: isActive ? Colors.white : AppTheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            isActive ? 'Premium Member' : 'Free Plan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? 'You have unlimited access to all features'
                : 'Upgrade to unlock premium features',
            style: TextStyle(
              fontSize: 14,
              color: isActive
                  ? Colors.white.withOpacity(0.85)
                  : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      _Benefit(Icons.all_inclusive_outlined, 'Unlimited Swaps'),
      _Benefit(Icons.hd_outlined, 'HD Quality Export'),
      _Benefit(Icons.water_drop_outlined, 'No Watermark'),
      _Benefit(Icons.bolt_outlined, 'Priority Processing'),
      _Benefit(Icons.auto_awesome_outlined, 'Exclusive Templates'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VIP Benefits',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(b.icon, color: AppTheme.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    b.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VipPurchaseScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Upgrade to Premium',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildManageButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          // 打开 App Store 订阅管理
          // iOS: 需要通过 URL scheme 打开
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(color: context.appColors.surfaceBackground),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Manage Subscription',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return Center(
      child: TextButton(
        onPressed: () async {
          final iap = context.read<SubscriptionService>();
          await iap.restorePurchases();
        },
        child: Text(
          'Restore Purchases',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  const _Benefit(this.icon, this.title);
}
