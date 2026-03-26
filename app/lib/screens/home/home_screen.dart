import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../widgets/tab_bar.dart';
import 'discover_screen.dart';
import 'create_screen.dart';
import 'works_screen.dart';
import 'profile_screen.dart';
import 'package:face_swap/providers/template_provider.dart';

/// 首页（Tab 容器）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// 页面列表
  final List<Widget> _screens = [
    const DiscoverScreen(),
    const DiscoverScreen(),
    const CreateScreen(),
    const WorksScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 初始加载模板数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().loadTemplates();
      context.read<TemplateProvider>().loadHotTemplates();
    });
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
