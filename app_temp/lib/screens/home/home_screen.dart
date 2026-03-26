import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/tab_bar.dart';
import '../../providers/generation_provider.dart';
import 'home_tab_screen.dart';
import 'create_screen.dart';
import 'works_screen.dart';
import 'profile_screen.dart';

/// 首页（Tab 容器）— 4 Tab: 首页 / 创作 / 作品 / 我的
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// 全局 Tab 控制器（供子页面切换 Tab）
  static final HomeTabController tabController = HomeTabController();

  /// Tab 可见性通知器 — 切换 Tab 时通知子页面刷新
  static final HomeTabVisibilityNotifier visibilityNotifier =
      HomeTabVisibilityNotifier();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// 4 个页面
  final List<Widget> _screens = const [
    HomeTabScreen(),
    CreateScreen(),
    WorksScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    HomeScreen.tabController.addListener(_onTabFromChild);
  }

  @override
  void dispose() {
    HomeScreen.tabController.removeListener(_onTabFromChild);
    super.dispose();
  }

  /// 子页面触发 Tab 切换
  void _onTabFromChild() {
    final target = HomeScreen.tabController.consume();
    if (target >= 0 && target != _currentIndex) {
      _switchToTab(target);
    }
  }

  void _onTabTap(int index) {
    _switchToTab(index);
  }

  void _switchToTab(int index) {
    final prevIndex = _currentIndex;
    setState(() => _currentIndex = index);

    // 通知子页面 Tab 切换
    HomeScreen.visibilityNotifier.switchTo(index);

    // 切到作品 Tab 时刷新历史
    if (index == 2 && prevIndex != 2) {
      context.read<GenerationProvider>().loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomTabBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

/// Tab 切换控制器
class HomeTabController extends ChangeNotifier {
  int _targetIndex = -1;

  int get targetIndex => _targetIndex;

  void switchTo(int index) {
    if (_targetIndex != index) {
      _targetIndex = index;
      notifyListeners();
    }
  }

  int consume() {
    final idx = _targetIndex;
    _targetIndex = -1;
    return idx;
  }
}

/// Tab 可见性通知器
class HomeTabVisibilityNotifier extends ChangeNotifier {
  int _currentTab = 0;

  int get currentTab => _currentTab;

  void switchTo(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }
}
