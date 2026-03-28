import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../widgets/tab_bar.dart';
import '../../providers/generation_provider.dart';
import '../../providers/user_provider.dart';
import 'home_tab_screen.dart';
import 'create_screen.dart';
import 'works_screen.dart';
import 'profile_screen.dart';

/// 主页面 — 4 Tab 导航
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Tab 控制器（供 ProfileScreen 切换 Tab 使用）
  static TabController? tabController;

  /// Tab 可见性通知器（供 HomeTabScreen 使用）
  static final ValueNotifier<int> visibilityNotifier = ValueNotifier(0);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<int> _tabNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    HomeScreen.tabController = _tabController;
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    HomeScreen.tabController = null;
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final index = _tabController.index;
      _tabNotifier.value = index;
      HomeScreen.visibilityNotifier.value = index;

      // Tab 切换时自动刷新数据
      if (!mounted) return;
      if (index == 2) {
        // Works tab — 刷新历史
        context.read<GenerationProvider>().loadHistory(refresh: true);
      } else if (index == 3) {
        // Profile tab — 刷新用户信息
        context.read<UserProvider>().loadUserProfile();
      }
    }
  }

  /// 处理返回手势：非首页 Tab → 回首页，首页 → 退出
  Future<bool> _onWillPop() async {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
      return false; // 拦截退出
    }
    return true; // 允许退出
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tabController.index == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // 非首页 Tab：切换到首页
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            HomeTabScreen(),
            CreateScreen(),
            WorksScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder<int>(
          valueListenable: _tabNotifier,
          builder: (context, currentIndex, _) {
            return AppBottomTabBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (index == currentIndex) return;
                _tabController.animateTo(index);
              },
            );
          },
        ),
      ),
    );
  }
}
