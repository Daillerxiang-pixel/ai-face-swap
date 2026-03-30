import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/image_utils.dart';
import '../create/select_template_screen.dart';
import 'home_screen.dart';

/// 创作页面（中间按钮的展示页）
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // 标题
              Text(
                'AI Face Swap',
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a template, upload a photo, create in one tap',
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              // 功能卡片
              _buildFeatureCard(
                context,
                icon: Icons.auto_awesome,
                title: 'Templates',
                subtitle: 'Choose a template, AI does the rest',
                gradient: AppTheme.primaryGradient,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SelectTemplateScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                icon: Icons.photo_library_outlined,
                title: 'My Works',
                subtitle: 'View generation history',
                gradient: const LinearGradient(
                  begin: Alignment(-1, -1),
                  end: Alignment(1, 1),
                  colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                ),
                onTap: () {
                  // 切换到作品 tab (index 2)
                  HomeScreen.tabController?.animateTo(2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 功能卡片
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          gradient: gradient,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: context.appColors.textPrimary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.appColors.textPrimary.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: context.appColors.textPrimary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
