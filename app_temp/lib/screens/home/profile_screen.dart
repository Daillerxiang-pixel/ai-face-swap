import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../profile/vip_purchase_screen.dart';
import '../profile/favorites_screen.dart';
import '../profile/settings_screen.dart';
import 'home_screen.dart';

/// 个人中心页面
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    setState(() {
      _isLoggedIn = AuthService().isLoggedIn;
    });
  }

  void _switchToTab(int index) {
    HomeScreen.tabController?.animateTo(index);
  }

  Future<void> _handleSignIn() async {
    final result = await Navigator.pushNamed(context, '/login');
    if (result == true) {
      // 登录成功，刷新用户信息
      _checkLogin();
      if (mounted) {
        context.read<UserProvider>().loadUserProfile();
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        title: Text('Sign Out', style: TextStyle(color: context.appColors.textPrimary)),
        content: Text('Are you sure you want to sign out?', style: TextStyle(color: context.appColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      AuthService().clearToken();
      context.read<UserProvider>().logout();
      _checkLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: context.appColors.cardBackground,
          onRefresh: () async {
            await context.read<UserProvider>().loadUserProfile();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
            // 头像 + 名字 + 用户信息
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // 第一行：头像 + 昵称 + 会员标签
                  Row(
                    children: [
                      Consumer<UserProvider>(builder: (ctx, userProvider, _) {
                        final user = userProvider.user;
                        final hasAvatar = user?.avatar != null && user!.avatar!.isNotEmpty;
                        return Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment(-1, -1),
                              end: Alignment(1, 1),
                              colors: hasAvatar ? [AppTheme.primary, const Color(0xFF3B82F6)] : [AppTheme.primary, const Color(0xFF3B82F6)],
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasAvatar
                              ? Image.network(user.avatar!, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 36))
                              : const Icon(Icons.person, color: Colors.white, size: 36),
                        );
                      }),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<UserProvider>(builder: (ctx, userProvider, _) {
                              final nickname = userProvider.user?.nickname ?? 'User';
                              return Text(
                                nickname,
                                style: TextStyle(
                                  color: context.appColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }),
                            const SizedBox(height: 4),
                            Consumer<UserProvider>(builder: (ctx, userProvider, _) {
                              final isVip = userProvider.isVip;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isVip
                                      ? const Color(0xFFF59E0B).withOpacity(0.15)
                                      : const Color(0xFF3B82F6).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isVip ? 'VIP Member' : 'Free Plan',
                                  style: TextStyle(
                                    color: isVip ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 第二行：统计数据
                  const SizedBox(height: 20),
                  Consumer<UserProvider>(builder: (ctx, userProvider, _) {
                    final user = userProvider.user;
                    final works = user?.totalGenerations ?? 0;
                    final credits = user?.remainCredits ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _buildStatItem('$works', 'Works'),
                          _buildStatDivider(),
                          _buildStatItem('0', 'Favorites'),
                          _buildStatDivider(),
                          _buildStatItem('$credits', 'Credits Left'),
                        ],
                      ),
                    );
                  }),
                  // 第三行：账户信息
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.mail_outline, color: context.appColors.textTertiary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Consumer<UserProvider>(builder: (ctx, userProvider, _) {
                          // 显示 userId 前8位作为标识
                          final userId = AuthService().userId ?? '';
                          final displayId = userId.isNotEmpty ? '${userId.substring(0, userId.length > 8 ? 8 : userId.length)}...' : 'Not signed in';
                          return Text(
                            _isLoggedIn ? 'ID: $displayId' : 'Not signed in',
                            style: TextStyle(color: context.appColors.textTertiary, fontSize: 13),
                          );
                        }),
                      ),
                      if (!_isLoggedIn)
                        GestureDetector(
                          onTap: _handleSignIn,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primary, width: 1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _handleSignOut,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: context.appColors.textTertiary.withOpacity(0.3), width: 1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Sign Out',
                              style: TextStyle(color: context.appColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // VIP 卡片
            _buildVipCard(context),
            const SizedBox(height: 16),

            // 菜单
            _buildMenu(context),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: context.appColors.textTertiary.withOpacity(0.2),
    );
  }

  Widget _buildVipCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VipPurchaseScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [Color(0xFF4A2D7A), Color(0xFF2D1B4E)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 22),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Upgrade to VIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Unlimited swaps & premium templates',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final items = [
      _MenuItem(Icons.favorite_outline, 'Favorites', () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
        );
      }),
      _MenuItem(Icons.history, 'History', () {
        _switchToTab(2); // Works tab
      }),
      _MenuItem(Icons.settings_outlined, 'Settings', () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      }),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: items.asMap().entries.map((e) {
        final item = e.value;
        final isLast = e.key == items.length - 1;
        return Column(
          children: [
            InkWell(
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: context.appColors.textSecondary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: context.appColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: context.appColors.textTertiary, size: 20),
                  ],
                ),
              ),
            ),
            if (!isLast)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 0.5, color: context.appColors.surfaceBackground),
              ),
          ],
        );
      }).toList()),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
}
