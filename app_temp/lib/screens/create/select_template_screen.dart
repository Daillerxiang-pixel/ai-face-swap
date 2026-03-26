import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../providers/template_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/template_card.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/toast.dart';
import 'upload_photo_screen.dart';

/// 选择模板页面 — 场景筛选 + 模板网格
class SelectTemplateScreen extends StatefulWidget {
  const SelectTemplateScreen({super.key});

  @override
  State<SelectTemplateScreen> createState() => _SelectTemplateScreenState();
}

class _SelectTemplateScreenState extends State<SelectTemplateScreen> {
  final ApiService _api = ApiService();

  /// 当前选中的场景
  String _currentScene = '全部';

  /// 当前选中的类型: null=全部, 'image', 'video'
  String? _currentType;

  /// 场景列表（从 API 动态获取）
  List<String> _scenes = ['全部'];

  /// 是否正在加载场景列表
  bool _isLoadingScenes = true;

  /// 是否正在下拉刷新模板
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadScenes();
    _loadTemplates();
  }

  /// 从 API 加载场景列表
  Future<void> _loadScenes() async {
    try {
      final res = await _api.getScenes();
      final scenes = (res.data as List?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];

      if (mounted) {
        setState(() {
          _scenes = ['全部', ...scenes];
          _isLoadingScenes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingScenes = false);
      }
    }
  }

  /// 加载模板
  void _loadTemplates() {
    final provider = context.read<TemplateProvider>();
    final scene = _currentScene == '全部' ? null : _currentScene;
    provider.loadTemplates(refresh: true, scene: scene, type: _currentType);
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);

    await _loadScenes();
    _loadTemplates();

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('选择模板'),
        actions: [
          // 类型筛选
          PopupMenuButton<String?>(
            icon: Icon(
              _currentType == 'video'
                  ? Icons.videocam
                  : _currentType == 'image'
                      ? Icons.image
                      : Icons.filter_list,
              color: _currentType != null ? AppTheme.primary : AppTheme.textSecondary,
              size: 22,
            ),
            color: AppTheme.cardBackground,
            onSelected: (value) {
              setState(() => _currentType = value);
              _loadTemplates();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部类型')),
              const PopupMenuItem(value: 'image', child: Text('📷 图片换脸')),
              const PopupMenuItem(value: 'video', child: Text('🎬 视频换脸')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 场景分类
          _buildSceneTabs(),
          // 模板网格
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.cardBackground,
              onRefresh: _onRefresh,
              child: Consumer<TemplateProvider>(
                builder: (context, provider, _) {
                  final isLoading =
                      provider.isLoading && provider.templates.isEmpty;

                  // 骨架屏
                  if (isLoading) {
                    return ListView(
                      children: [
                        _buildSceneTabsPlaceholder(),
                        const SizedBox(height: 8),
                        TemplateCardShimmer(),
                      ],
                    );
                  }

                  // 错误状态
                  if (provider.error != null &&
                      provider.templates.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        EmptyStateWidget(
                          icon: Icons.wifi_off_outlined,
                          title: '加载失败',
                          subtitle: provider.error,
                          actionText: '重试',
                          onAction: () => _loadTemplates(),
                        ),
                      ],
                    );
                  }

                  // 空状态
                  if (provider.templates.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyStateWidget(
                          icon: Icons.image_not_supported_outlined,
                          title: '暂无模板',
                          subtitle: '更多模板即将上线',
                        ),
                      ],
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
      child: _isLoadingScenes
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _scenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final scene = _scenes[index];
                final isSelected = scene == _currentScene;
                return GestureDetector(
                  onTap: () {
                    if (scene == _currentScene) return;
                    setState(() => _currentScene = scene);
                    _loadTemplates();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  /// 场景标签占位符（骨架屏用）
  Widget _buildSceneTabsPlaceholder() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => const ShimmerWidget.rectangular(
          height: 30,
          width: 60,
          borderRadius: 15,
        ),
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
