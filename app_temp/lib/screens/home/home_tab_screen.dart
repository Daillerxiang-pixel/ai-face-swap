import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/shimmer_widget.dart';
import '../create/select_template_screen.dart';
import '../detail/template_detail_screen.dart';
import 'home_screen.dart';

/// 首页 Tab 0 — Banner + 精选推荐网格
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Template> _recTemplates = [];
  Template? _bannerTemplate;
  bool _isLoading = true;
  bool _isRefreshing = false;
  DateTime? _lastLoadTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    HomeScreen.visibilityNotifier.addListener(_onTabVisibilityChanged);
  }

  @override
  void dispose() {
    HomeScreen.visibilityNotifier.removeListener(_onTabVisibilityChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabVisibilityChanged() {
    if (HomeScreen.visibilityNotifier.currentTab == 0) {
      final now = DateTime.now();
      if (_lastLoadTime == null ||
          now.difference(_lastLoadTime!).inMinutes > 5) {
        _loadData(isRefresh: true);
      }
    }
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _api.getTemplates(limit: 9);
      final rec = (result.data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final banner = rec.isNotEmpty ? rec.first : null;

      if (mounted) {
        setState(() {
          _recTemplates = rec;
          _bannerTemplate = banner;
          _lastLoadTime = DateTime.now();
        });
      }
    } catch (e, stack) {
      debugPrint('[HomeTab] 数据加载失败: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatCount(int? count) {
    if (count == null || count == 0) return '0';
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}K';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 固定标题区域（不滚动，与 WorksScreen 对齐）
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI 换图',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // 可滚动内容
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: AppTheme.cardBackground,
                onRefresh: () => _loadData(isRefresh: true),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildBanner()),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(
                        '💡 精选推荐',
                        onMore: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SelectTemplateScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    _isLoading ? _buildRecShimmer() : _buildRecGrid(),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final tpl = _bannerTemplate;
    final bannerPreviewUrl =
        tpl != null ? ImageUtils.imgUrl(tpl.displayUrl) : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: GestureDetector(
        onTap: () {
          if (tpl != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TemplateDetailScreen(template: tpl),
              ),
            );
          }
        },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment(-1, -1),
              end: Alignment(1, 1),
              colors: [Color(0xFF5B21B6), Color(0xFF1D4ED8)],
            ),
          ),
          child: Stack(
            children: [
              if (bannerPreviewUrl.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  width: 200,
                  height: 180,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Opacity(
                      opacity: 0.35,
                      child: CachedNetworkImage(
                        imageUrl: bannerPreviewUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              const Positioned(
                right: -10,
                bottom: -10,
                child: Text(
                  '🎭',
                  style: TextStyle(fontSize: 120, color: Colors.white10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ 今日精选',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tpl?.name ?? '一键换脸\n惊艳全场',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_formatCount(tpl?.useCount)} 人已使用',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text(
                        '立即体验',
                        style: TextStyle(
                          color: Color(0xFF5B21B6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onMore}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: const Text(
                '查看更多 ›',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => ShimmerWidget.rectangular(
            borderRadius: 14,
          ),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildRecGrid() {
    if (_recTemplates.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tpl = _recTemplates[index];
            return _buildRecCard(tpl);
          },
          childCount: _recTemplates.length,
        ),
      ),
    );
  }

  Widget _buildRecCard(Template tpl) {
    final thumbUrl = ImageUtils.imgUrl(tpl.displayUrl);
    final isVideo = tpl.isVideo;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TemplateDetailScreen(template: tpl),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumbUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.surfaceBackground,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceBackground,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTheme.textTertiary,
                          size: 42,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceBackground,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.textTertiary,
                        size: 42,
                      ),
                    ),
                  if (isVideo)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tpl.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatCount(tpl.useCount)} 次使用',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVideo
                              ? const Color(0xFFFF3B30).withOpacity(0.15)
                              : AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isVideo) ...[
                              const Icon(Icons.videocam_outlined,
                                  color: Color(0xFFFF3B30), size: 10),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              isVideo ? '视频' : '换脸',
                              style: TextStyle(
                                color: isVideo
                                    ? const Color(0xFFFF3B30)
                                    : AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
