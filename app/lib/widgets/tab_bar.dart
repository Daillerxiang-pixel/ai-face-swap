import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 底部 Tab 栏组件
class AppBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(
          top: BorderSide(
            color: AppTheme.surfaceBackground,
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          // 底部导航项
          Padding(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                _buildTabItem(context, 0, Icons.home_outlined, '首页'),
                const SizedBox(width: 12),
                _buildTabItem(context, 1, Icons.explore_outlined, '发现'),
                const SizedBox(width: 12),
                // 中间创作按钮（占位）
                const Expanded(child: SizedBox()),
                const SizedBox(width: 12),
                _buildTabItem(context, 3, Icons.grid_view_outlined, '作品'),
                const SizedBox(width: 12),
                _buildTabItem(context, 4, Icons.person_outline, '我的'),
              ],
            ),
          ),
          // 中间突出圆形创作按钮
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(top: -8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_fix_high,
                    color: AppTheme.textPrimary,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 Tab 项
  Widget _buildTabItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppTheme.primary : AppTheme.textTertiary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
