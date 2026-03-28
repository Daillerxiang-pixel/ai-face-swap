import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../providers/template_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/template_card.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'upload_photo_screen.dart';

/// Template browser — All/Photo/Video toggle + scene category tabs + grid
class SelectTemplateScreen extends StatefulWidget {
  final String? initialType;

  const SelectTemplateScreen({super.key, this.initialType});

  @override
  State<SelectTemplateScreen> createState() => _SelectTemplateScreenState();
}

class _SelectTemplateScreenState extends State<SelectTemplateScreen> {
  final ApiService _api = ApiService();

  String _currentScene = 'All';
  String? _currentType;
  List<String> _scenes = ['All'];
  bool _isLoadingScenes = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _loadScenes();
    _loadTemplates();
  }

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
          _scenes = ['All', ...scenes];
          _isLoadingScenes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingScenes = false);
    }
  }

  void _loadTemplates() {
    final provider = context.read<TemplateProvider>();
    final scene = _currentScene == 'All' ? null : _currentScene;
    provider.loadTemplates(refresh: true, scene: scene, type: _currentType);
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadScenes();
    _loadTemplates();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: AppTheme.primary, size: 28),
              SizedBox(width: 0),
              Text('Back', style: TextStyle(color: AppTheme.primary, fontSize: 17)),
            ],
          ),
        ),
        title: const Text('Templates'),
        actions: [],
      ),
      body: Column(
        children: [
          // All / Photo / Video toggle
          _buildTypeToggle(),
          // Scene category tabs
          _buildSceneTabs(),
          // Sort row
          Consumer<TemplateProvider>(
            builder: (context, provider, _) => _buildSortRow(provider.templates.length),
          ),
          // Grid
          Expanded(
            child: Consumer<TemplateProvider>(
              builder: (context, provider, _) {
                final isLoading = provider.isLoading && provider.templates.isEmpty;

                if (isLoading) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => ShimmerWidget.rectangular(borderRadius: 14),
                  );
                }

                if (provider.error != null && provider.templates.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 120),
                      EmptyStateWidget(
                        icon: Icons.wifi_off_outlined,
                        title: 'Failed to load',
                        subtitle: provider.error,
                        actionText: 'Retry',
                        onAction: () => _loadTemplates(),
                      ),
                    ],
                  );
                }

                if (provider.templates.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyStateWidget(
                        icon: Icons.image_not_supported_outlined,
                        title: 'No templates yet',
                        subtitle: 'More templates coming soon',
                      ),
                    ],
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.cardBackground,
                  onRefresh: _onRefresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: provider.templates.length,
                    itemBuilder: (context, index) {
                      final template = provider.templates[index];
                      return TemplateCard(
                        template: template,
                        onTap: () => _onTemplateSelected(template),
                        onFavorite: () => provider.toggleFavorite(template.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    const labels = ['All', 'Photo', 'Video'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (int i = 0; i < 3; i++)
              _buildTypeToggleItem(i),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggleItem(int index) {
    const labels = ['All', 'Photo', 'Video'];
    final isActive = (index == 0 && _currentType == null) ||
        (index == 1 && _currentType == 'image') ||
        (index == 2 && _currentType == 'video');
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentType = index == 0 ? null : (index == 1 ? 'image' : 'video'));
          _loadTemplates();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : null,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            labels[index],
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSceneTabs() {
    return SizedBox(
      height: 40,
      child: _isLoadingScenes
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        scene,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSortRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            '$count templates',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, color: AppTheme.textSecondary, size: 14),
              SizedBox(width: 4),
              Text(
                'Popular',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTemplateSelected(Template template) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UploadPhotoScreen(template: template)),
    );
  }
}
