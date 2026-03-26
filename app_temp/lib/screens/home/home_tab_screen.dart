import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/shimmer_widget.dart';
import '../create/select_template_screen.dart';
import 'discover_screen.dart';
import 'home_screen.dart';

/// 首页 Tab 0 — Banner + 热门横向滚动 + 精选推荐网格
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  /// 热门模板
  List<Template> _hotTemplates = [];

  /// 推荐模板
  List<Template> _recTemplates = [];

  /// Banner 模板（取热门第一个）
  Template? _bannerTemplate;

  bool _isLoading = true;

  /// 是否正在下拉刷新
  bool _isRefreshing = false;

  /// 上一次加载数据的时间
  DateTime? _lastLoadTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 监听 Tab 切换，切回首页时刷新数据
    HomeScreen.visibilityNotifier.addListener(_onTabVisibilityChanged);
  }

  @override
  void dispose() {
    HomeScreen.visibilityNotifier.removeListener(_onTabVisibilityChanged);
    _scrollController.dispose();
    super.dispose();
  }

  /// Tab 可见性变化回调 — 切回首页时智能刷新
  void _onTabVisibilityChanged() {
    if (HomeScreen.visibilityNotifier.currentTab == 0) {
      // 5 分钟内不重复加载
      final now = DateTime.now();
      if (_lastLoadTime == null ||
          now.difference(_lastLoadTime!).inMinutes > 5) {
        _loadData(isRefresh: true);
      }
    }
  }

  /// 并行加载热门 + 推荐
  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _api.getTemplates(sort: 'usage', limit: 10),
        _api.getTemplates(limit: 8),
      ]);

      final hot = (results[0].data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final rec = (results[1].data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      // Banner 取热门第一个
      final banner = hot.isNotEmpty ? hot.first : null;

      if (mounted) {
        setState(() {
          _hotTemplates = hot;
          _recTemplates = rec;
          _bannerTemplate = banner;
          _lastLoadTime = DateTime.now();
        });
      }
    } catch (e) {
      // 加载失败 — 打印日志便于排查
      debugPrint('[HomeTab] 数据加载失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  /// 格式化使用次数
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
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: () => _loadData(isRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ===== 顶部标题 =====
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.background,
                      AppTheme.background.withOpacity(0.85),
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 换图',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '发现你的另一种可能',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Banner =====
            SliverToBoxAdapter(child: _buildBanner()),

            // ===== 热门模板 =====
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                '🔥 热门模板',
                onMore: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiscoverScreen(),
                    ),
                  );
                },
              ),
            ),
            _isLoading ? _buildHotShimmer() : _buildHotScroll(),

            // ===== 精选推荐 =====
            SliverToBoxAdapter(
              child: _buildSectionTitle('💡 精选推荐'),
            ),
            _isLoading ? _buildRecShimmer() : _buildRecGrid(),

            // 底部间距
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  /// Banner 大卡片
  Widget _buildBanner() {
    final tpl = _bannerTemplate;
    final bannerPreviewUrl =
        tpl != null ? ImageUtils.imgUrl(tpl.displayUrl) : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SelectTemplateScreen(),
            ),
          );
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
              // 背景图（半透明）
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

              // 装饰 emoji
              const Positioned(
                right: -10,
                bottom: -10,
                child: Text(
                  '🎭',
                  style: TextStyle(fontSize: 120, color: Colors.white10),
                ),
              ),

              // 文字内容
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

  /// 区块标题
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

  /// 热门模板骨架屏
  Widget _buildHotShimmer() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(left: 20, right: 20),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ShimmerWidget.rectangular(
              width: 140,
              height: 140,
              borderRadius: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// 热门模板横向滚动
  Widget _buildHotScroll() {
    if (_hotTemplates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(left: 20, right: 20),
          itemCount: _hotTemplates.length,
          itemBuilder: (context, index) {
            final tpl = _hotTemplates[index];
            return _buildHotCard(tpl, index);
          },
        ),
      ),
    );
  }

  /// 热门卡片
  Widget _buildHotCard(Template tpl, int index) {
    final thumbUrl = ImageUtils.imgUrl(tpl.displayUrl);
    final isFirst = index == 0;
    final isBadgeHot = tpl.badge?.toUpperCase() == 'HOT';
    final isVideo = tpl.isVideo;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _navigateToCreate(context, tpl),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (thumbUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumbUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: _getGradient(index),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: _getGradient(index),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: _getGradient(index),
                  ),
                ),

              // 视频标识
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
                      size: 18,
                    ),
                  ),
                ),

              // Badge
              if (isBadgeHot || isFirst)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        begin: Alignment(-1, -1),
                        end: Alignment(1, 1),
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                    ),
                    child: const Text(
                      'HOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 精选推荐骨架屏
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

  /// 精选推荐网格
  Widget _buildRecGrid() {
    if (_recTemplates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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

  /// 推荐卡片
  Widget _buildRecCard(Template tpl) {
    final thumbUrl = ImageUtils.imgUrl(tpl.displayUrl);
    final isVideo = tpl.isVideo;

    return GestureDetector(
      onTap: () => _navigateToCreate(context, tpl),
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

                  // 视频标识
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

  LinearGradient _getGradient(int index) {
    final gradients = [
      const [Color(0xFF7C3AED), Color(0xFF3B82F6)],
      const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      const [Color(0xFFF59E0B), Color(0xFFEF4444)],
      const [Color(0xFF10B981), Color(0xFF06B6D4)],
      const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
      const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      const [Color(0xFFEF4444), Color(0xFFF59E0B)],
      const [Color(0xFF06B6D4), Color(0xFF10B981)],
    ];
    final g = gradients[index % gradients.length];
    return LinearGradient(
      begin: Alignment(-1, -1),
      end: Alignment(1, 1),
      colors: [g[0], g[1]],
    );
  }

  /// 点击模板 → 跳转创作页
  void _navigateToCreate(BuildContext context, Template template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SelectTemplateScreen(),
      ),
    );
  }
}
