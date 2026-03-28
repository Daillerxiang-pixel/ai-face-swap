import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 底部 Tab 栏组件 — 4 Tab: 首页 / 创作 / 作品 / 我的
class AppBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Tab 配置
  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.auto_fix_high_outlined, Icons.auto_fix_high, 'Create'),
    (Icons.grid_view_outlined, Icons.grid_view, 'Works'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(
          top: BorderSide(
            color: AppTheme.surfaceBackground,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final (iconOut, iconIn, label) = _tabs[index];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          currentIndex == index ? iconIn : iconOut,
                          key: ValueKey('$index-${currentIndex == index}'),
                          color: currentIndex == index
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: currentIndex == index
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: currentIndex == index
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
