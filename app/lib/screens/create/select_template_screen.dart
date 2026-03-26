import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../providers/template_provider.dart';
import '../../widgets/template_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'upload_photo_screen.dart';

/// 选择模板页面
class SelectTemplateScreen extends StatefulWidget {
  const SelectTemplateScreen({super.key});

  @override
  State<SelectTemplateScreen> createState() => _SelectTemplateScreenState();
}

class _SelectTemplateScreenState extends State<SelectTemplateScreen> {
  String _currentScene = '全部';
  final List<String> _scenes = ['全部', '风景', '人像', '动漫', '电影', '搞笑'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('选择模板'),
      ),
      body: Column(
        children: [
          // 场景分类
          _buildSceneTabs(),
          // 模板网格
          Expanded(
            child: Consumer<TemplateProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.templates.isEmpty) {
                  return const LoadingWidget(message: '加载模板中...');
                }

                if (provider.templates.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.image_not_supported_outlined,
                    title: '暂无模板',
                    subtitle: '更多模板即将上线',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: provider.templates.length,
                  itemBuilder: (context, index) {
                    final template = provider.templates[index];
                    return TemplateCard(
                      template: template,
                      onTap: () => _onTemplateSelected(template),
                      onFavorite: () =>
                          provider.toggleFavorite(template.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 场景分类标签
  Widget _buildSceneTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _scenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final scene = _scenes[index];
          final isSelected = scene == _currentScene;
          return GestureDetector(
            onTap: () {
              setState(() => _currentScene = scene);
              final provider = context.read<TemplateProvider>();
              provider.loadTemplates(
                refresh: true,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  scene,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 选中模板
  void _onTemplateSelected(Template template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UploadPhotoScreen(template: template),
      ),
    );
  }
}
