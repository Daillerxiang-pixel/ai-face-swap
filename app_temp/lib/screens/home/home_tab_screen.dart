import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/template_media_thumb.dart';
import '../create/select_template_screen.dart';
import '../detail/template_detail_screen.dart';
import 'home_screen.dart';

/// 首页 Tab
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Template> _allTemplates = [];
  List<Template> _recTemplates = [];
  Template? _bannerTemplate;
  bool _isLoading = true;
  DateTime? _lastLoadTime;
  /// 全库数量（来自 /api/templates/meta/counts）；为 null 表示接口失败，退回本地推算
  int? _imageTotalCount;
  int? _videoTotalCount;

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
    if (HomeScreen.visibilityNotifier.value == 0) {
      final now = DateTime.now();
      if (_lastLoadTime == null ||
          now.difference(_lastLoadTime!).inMinutes > 5) {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final templatesFuture = _api.getTemplates(limit: 20);
      final countsFuture = _api.getTemplateTypeCounts();
      final result = await templatesFuture;
      ApiResponse<Map<String, dynamic>>? countRes;
      try {
        countRes = await countsFuture;
      } catch (_) {
        countRes = null;
      }

      final all = (result.data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final banner = all.isNotEmpty ? all.first : null;
      final rec = all.take(9).toList();

      int? imgTotal;
      int? vidTotal;
      if (countRes != null &&
          countRes.success &&
          countRes.data != null &&
          countRes.data!.isNotEmpty) {
        final d = countRes.data!;
        imgTotal = _parsePositiveInt(d['image']);
        vidTotal = _parsePositiveInt(d['video']);
      }

      if (mounted) {
        setState(() {
          _allTemplates = all;
          _recTemplates = rec;
          _bannerTemplate = banner;
          _imageTotalCount = imgTotal;
          _videoTotalCount = vidTotal;
          _lastLoadTime = DateTime.now();
        });
      }
    } catch (e, stack) {
      debugPrint('[HomeTab] 数据加载失败: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load data')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _parsePositiveInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v < 0 ? null : v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
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

    // 全库数量优先；接口失败时退回当前页列表统计（仅作降级）
    final imageCount = _imageTotalCount ??
        _allTemplates.where((t) => t.type == 'image').length;
    final videoCount = _videoTotalCount ??
        _allTemplates.where((t) => t.type == 'video').length;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed title
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              alignment: Alignment.centerLeft,
              child: Text(
                'AI FaceSwap',
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Scrollable content
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: context.appColors.cardBackground,
                onRefresh: _loadData,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    // Banner
                    _buildBanner(),
                    // Photo/Video entry cards
                    _buildQuickEntries(imageCount, videoCount),
                    // Trending
                    _buildSectionTitle('🔥 Trending', onMore: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SelectTemplateScreen()),
                      );
                    }),
                    _buildTrendingScroll(),
                    // Featured grid
                    _buildSectionTitle('💡 Featured', onMore: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SelectTemplateScreen()),
                      );
                    }),
                    _isLoading ? _buildRecShimmer() : _buildRecGrid(),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: GestureDetector(
        onTap: () {
          if (tpl != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TemplateDetailScreen(template: tpl)),
            );
          }
        },
        child: Container(
          height: 160,
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
              if (tpl != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Opacity(
                      opacity: 0.3,
                      child: TemplateMediaThumb(template: tpl, fit: BoxFit.cover),
                    ),
                  ),
                ),
              const Positioned(
                right: -10,
                bottom: -10,
                child: Text('🎭', style: TextStyle(fontSize: 100, color: Colors.white10)),
              ),
              // Tag top-right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "✨ Today's Pick",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tpl?.name ?? 'Travel Adventure',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatCount(tpl?.useCount)} uses',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Try Now button
              Positioned(
                bottom: 16,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Try Now',
                    style: TextStyle(color: Color(0xFF5B21B6), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickEntries(int imageCount, int videoCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Photo Swap
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SelectTemplateScreen(initialType: 'image')),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary.withOpacity(0.8), const Color(0xFF3B82F6).withOpacity(0.8)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.2,
                        child: CachedNetworkImage(
                          imageUrl: _allTemplates.where((t) => t.type == 'image').firstOrNull != null
                              ? ImageUtils.imgUrl(_allTemplates.where((t) => t.type == 'image').first.displayUrl)
                              : '',
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Photo Swap', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('$imageCount templates', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Video Swap
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SelectTemplateScreen(initialType: 'video')),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFFFF3B30).withOpacity(0.8), const Color(0xFFF59E0B).withOpacity(0.8)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.2,
                        child: CachedNetworkImage(
                          imageUrl: _allTemplates.where((t) => t.type == 'video').firstOrNull != null
                              ? ImageUtils.imgUrl(_allTemplates.where((t) => t.type == 'video').first.displayUrl)
                              : '',
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Video Swap', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('$videoCount templates', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
            style: TextStyle(color: context.appColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: const Text('View All ›', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingScroll() {
    final items = _allTemplates.take(5).toList();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tpl = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TemplateDetailScreen(template: tpl)),
              );
            },
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with Before/After label
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TemplateMediaThumb(template: tpl, fit: BoxFit.cover),
                        // BA labels
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 8,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Before', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('After', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // User info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    HSLColor.fromColor(AppTheme.primary).withLightness(0.5).toColor(),
                                    const Color(0xFF3B82F6),
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 12),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'User #${tpl.id}',
                                style: TextStyle(color: context.appColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.favorite, color: Color(0xFFFF3B30), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              _formatCount(tpl.useCount),
                              style: TextStyle(color: context.appColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tpl.name,
                          style: TextStyle(color: context.appColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildRecGrid() {
    if (_recTemplates.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _recTemplates.length,
      itemBuilder: (context, index) {
        final tpl = _recTemplates[index];
        final isVideo = tpl.isVideoWorkflow;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TemplateDetailScreen(template: tpl)),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
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
                      TemplateMediaThumb(template: tpl, fit: BoxFit.cover),
                      if (isVideo)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
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
                        style: TextStyle(color: context.appColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatCount(tpl.useCount),
                            style: TextStyle(color: context.appColors.textSecondary, fontSize: 11),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isVideo
                                  ? const Color(0xFFFF3B30).withOpacity(0.15)
                                  : AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isVideo ? 'Video' : 'Swap',
                              style: TextStyle(
                                color: isVideo ? const Color(0xFFFF3B30) : AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
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
      },
    );
  }
}
