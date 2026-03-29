import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPressed;

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
        context.read<GenerationProvider>().loadHistory(refresh: true);
      } else if (index == 3) {
        context.read<UserProvider>().loadUserProfile();
      }
    }
  }

  void _onBackPress() {
    final now = DateTime.now();

    if (_tabController.index != 0) {
      // 非首页 Tab → 回首页
      _tabController.animateTo(0);
      _lastBackPressed = null;
      return;
    }

    // 首页 Tab → 双击退出
    if (_lastBackPressed == null || now.difference(_lastBackPressed!).inSeconds > 2) {
      // 第一次按返回 → 提示
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // 2秒内第二次按返回 → 退出应用
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 拦截所有返回，由 _onBackPress 处理
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBackPress();
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
