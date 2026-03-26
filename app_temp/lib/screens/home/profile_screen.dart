import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../utils/image_utils.dart';
import '../profile/vip_screen.dart';
import '../profile/favorites_screen.dart';
import '../profile/settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart';

/// 我的页面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, provider, _) {
            final user = provider.user;
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 头像 + 昵称
                  _buildProfileHeader(context, user, provider),
                  const SizedBox(height: 24),
                  // 统计数据
                  _buildStats(user),
                  const SizedBox(height: 20),
                  // VIP 入口
                  _buildVipCard(context),
                  const SizedBox(height: 16),
                  // 菜单项
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite_outline,
                    title: '我的收藏',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: '生成记录',
                    onTap: () {
                      // 切换到作品 Tab (index 2)
                      HomeScreen.tabController.switchTo(2);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: '设置',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 用户头像和昵称
  Widget _buildProfileHeader(BuildContext context, user, UserProvider provider) {
    final avatarUrl = ImageUtils.imgUrl(user?.avatar);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 64,
              height: 64,
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.primary,
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.textPrimary,
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.primary,
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.textPrimary,
                        size: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.nickname ?? 'AI换图用户',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (user?.isVip ?? false)
                      ? AppTheme.primary.withOpacity(0.2)
                      : AppTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (user?.isVip ?? false)
                          ? Icons.workspace_premium
                          : Icons.workspace_premium_outlined,
                      size: 14,
                      color: (user?.isVip ?? false)
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      (user?.isVip ?? false) ? 'VIP会员' : '普通用户',
                      style: TextStyle(
                        fontSize: 12,
                        color: (user?.isVip ?? false)
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 统计数据
  Widget _buildStats(user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('生成次数', '${user?.totalGenerations ?? 0}'),
            Container(
              width: 1,
              height: 32,
              color: AppTheme.surfaceBackground,
            ),
            _buildStatItem('剩余次数', '${user?.remainCredits ?? 0}'),
            Container(
              width: 1,
              height: 32,
              color: AppTheme.surfaceBackground,
            ),
            _buildStatItem('收藏', '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// VIP 卡片
  Widget _buildVipCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VipScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            gradient: const LinearGradient(
              begin: Alignment(-1, -0.5),
              end: Alignment(1, 0.5),
              colors: [Color(0xFF4A2D7A), Color(0xFF2D1B4E)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '开通VIP会员',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '享受无限次生成、高清无水印',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '开通 >',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 菜单项
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.surfaceBackground,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
