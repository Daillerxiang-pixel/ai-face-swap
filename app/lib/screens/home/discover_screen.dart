import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../providers/template_provider.dart';
import '../../widgets/template_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/image_utils.dart';
import '../detail/template_detail_screen.dart';

/// 首页 - 发现页面（Banner + 热门 + 推荐）
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Banner 数据
  final List<Map<String, String>> _banners = [
    {
      'image': 'https://aihuantu.oss-cn-beijing.aliyuncs.com/banner/01.jpg',
      'title': 'AI换脸 新体验',
    },
    {
      'image': 'https://aihuantu.oss-cn-beijing.aliyuncs.com/banner/02.jpg',
      'title': '海量模板 等你探索',
    },
    {
      'image': 'https://aihuantu.oss-cn-beijing.aliyuncs.com/banner/03.jpg',
      'title': 'VIP会员 特权专享',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动到底部加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TemplateProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 顶部标题
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            // Banner
            SliverToBoxAdapter(
              child: _buildBanner(),
            ),
            // 热门模板
            SliverToBoxAdapter(
              child: _buildSectionTitle('🔥 热门模板', onMore: () {}),
            ),
            _buildHotTemplates(),
            // 推荐模板
            SliverToBoxAdapter(
              child: _buildSectionTitle('✨ 为你推荐'),
            ),
            _buildRecommendedTemplates(),
            // 底部间距
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  /// 顶部标题栏
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          const Text(
            '发现',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 搜索按钮
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner 轮播
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 160,
        child: PageView.builder(
          itemCount: _banners.length,
          itemBuilder: (context, index) {
            final banner = _banners[index];
            return Padding(
              padding: EdgeInsets.only(right: index < _banners.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: banner['image'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.surfaceBackground,
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                          ),
                        ),
                      ),
                      // 渐变遮罩
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      // 文字
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Text(
                          banner['title'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 区块标题
  Widget _buildSectionTitle(String title, {VoidCallback? onMore}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Row(
                children: const [
                  Text(
                    '更多',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 热门模板横向滚动
  Widget _buildHotTemplates() {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        final templates = provider.hotTemplates;
        if (templates.isEmpty && provider.isLoading) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (context, _) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (templates.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 130,
                    child: TemplateCard(
                      template: template,
                      width: 130,
                      onTap: () => _navigateToDetail(context, template),
                      onFavorite: () =>
                          provider.toggleFavorite(template.id),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 推荐模板网格
  Widget _buildRecommendedTemplates() {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        final templates = provider.templates;

        if (provider.isLoading && templates.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: LoadingWidget(message: '加载中...'),
            ),
          );
        }

        if (templates.isEmpty && provider.error != null) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EmptyStateWidget(
                icon: Icons.error_outline,
                title: '加载失败',
                subtitle: provider.error,
                actionText: '重试',
                onAction: () => provider.loadTemplates(refresh: true),
              ),
            ),
          );
        }

        if (templates.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyStateWidget(
              icon: Icons.auto_awesome_outlined,
              title: '暂无模板',
              subtitle: '更多精彩模板即将上线',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final template = templates[index];
                return TemplateCard(
                  template: template,
                  onTap: () => _navigateToDetail(context, template),
                  onFavorite: () =>
                      provider.toggleFavorite(template.id),
                );
              },
              childCount: templates.length +
                  (provider.isLoadingMore ? 2 : 0),
            ),
          ),
        );
      },
    );
  }

  /// 跳转模板详情
  void _navigateToDetail(BuildContext context, Template template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateDetailScreen(template: template),
      ),
    );
  }
}
