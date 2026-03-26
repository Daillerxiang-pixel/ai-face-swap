import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../config/theme.dart';
import '../../models/generation.dart';
import '../../providers/generation_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/toast.dart';

/// 作品页面 — 筛选 + 日期分组 + 视图切换 + 点击交互
/// 参考 index-v4.html worksPage
class WorksScreen extends StatefulWidget {
  const WorksScreen({super.key});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  /// 当前筛选: all / success / fail
  String _filter = 'all';

  /// 网格列数: 3 或 2
  int _crossAxisCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenerationProvider>().loadHistory();
    });
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await context.read<GenerationProvider>().loadHistory(refresh: true);
  }

  /// 筛选列表
  List<Generation> _getFilteredList(List<Generation> all) {
    switch (_filter) {
      case 'success':
        return all.where((w) => w.isCompleted).toList();
      case 'fail':
        return all.where((w) => w.isFailed).toList();
      default:
        return all;
    }
  }

  /// 按日期分组，返回有序 Map<日期标签, List<Generation>>
  Map<String, List<Generation>> _groupByDate(List<Generation> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Generation>> groups = {};

    for (final item in items) {
      final createdAt = item.createdAt;
      if (createdAt == null) continue;

      final itemDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

      String label;
      if (itemDate == today) {
        label = '今天';
      } else if (itemDate == yesterday) {
        label = '昨天';
      } else if (itemDate.year == now.year) {
        label = '${createdAt.month}月${createdAt.day}日';
      } else {
        label = '${createdAt.year}年${createdAt.month}月${createdAt.day}日';
      }

      groups.putIfAbsent(label, () => []).add(item);
    }

    return groups;
  }

  /// 提取时间 (HH:mm)
  String _extractTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 点击作品
  void _onWorkTap(Generation item) {
    if (item.isCompleted && (item.resultImage?.isNotEmpty ?? false)) {
      _showResultPreview(item);
    } else if (item.isFailed) {
      _showErrorDialog(item);
    }
  }

  /// 全屏预览结果图
  void _showResultPreview(Generation item) {
    final imageUrl = ImageUtils.imgUrl(item.resultImage);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ResultPreviewScreen(
          imageUrl: imageUrl,
          isVideo: item.isVideo,
        ),
      ),
    );
  }

  /// 显示错误信息弹窗
  void _showErrorDialog(Generation item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text(
              '生成失败',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          item.errorMessage ?? '未知错误，请重试',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '关闭',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '作品',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 筛选栏
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  // 左侧筛选按钮
                  _buildFilterBtn('全部', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterBtn('成功', 'success'),
                  const SizedBox(width: 8),
                  _buildFilterBtn('失败', 'fail'),

                  const Spacer(),

                  // 右侧视图切换
                  _buildViewToggle(),
                ],
              ),
            ),

            // 内容列表
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: AppTheme.cardBackground,
                onRefresh: _onRefresh,
                child: Consumer<GenerationProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.history.isEmpty) {
                      return const LoadingWidget(message: '加载中...');
                    }

                    final filtered = _getFilteredList(provider.history);

                    if (filtered.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 120),
                          EmptyStateWidget(
                            icon: Icons.palette_outlined,
                            title: '暂无作品',
                            subtitle: '快去创作你的第一幅作品吧',
                          ),
                        ],
                      );
                    }

                    final groups = _groupByDate(filtered);

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final label = groups.keys.elementAt(index);
                        final items = groups[label]!;

                        return _buildDateGroup(label, items);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterBtn(String label, String filterKey) {
    final isActive = _filter == filterKey;
    return GestureDetector(
      onTap: () {
        if (_filter == filterKey) return;
        setState(() => _filter = filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// 构建视图切换按钮
  Widget _buildViewToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _crossAxisCount = _crossAxisCount == 3 ? 2 : 3;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _crossAxisCount == 3
              ? Icons.grid_view
              : Icons.view_module_outlined,
          color: AppTheme.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  /// 构建日期分组
  Widget _buildDateGroup(String dateLabel, List<Generation> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildWorkItem(items[index]);
            },
          ),
        ],
      ),
    );
  }

  /// 构建单个作品项
  Widget _buildWorkItem(Generation item) {
    final isSuccess = item.isCompleted;
    final resultUrl = ImageUtils.imgUrl(item.resultImage);
    final time = _extractTime(item.createdAt);
    final isVideo = item.isVideo;

    return GestureDetector(
      onTap: () => _onWorkTap(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          color: AppTheme.cardBackground,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 缩略图
                if (resultUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: resultUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.surfaceBackground,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surfaceBackground,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppTheme.textTertiary,
                        size: 28,
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppTheme.surfaceBackground,
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.textTertiary,
                      size: 28,
                    ),
                  ),

                // 视频标识
                if (isVideo)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            '视频',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 右下角时间
                if (time.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 右上角状态标记
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isSuccess ? '✓' : '✕',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 全屏图片预览页面（支持保存到相册）
class _ResultPreviewScreen extends StatefulWidget {
  final String imageUrl;
  final bool isVideo;

  const _ResultPreviewScreen({required this.imageUrl, this.isVideo = false});

  @override
  State<_ResultPreviewScreen> createState() => _ResultPreviewScreenState();
}

class _ResultPreviewScreenState extends State<_ResultPreviewScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white),
        actions: [
          if (!widget.isVideo)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download, color: Colors.white),
              onPressed: _isSaving ? null : _saveToGallery,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                onPressed: _isSaving ? null : _saveToGallery,
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: AppTheme.textTertiary,
                    size: 48,
                  ),
                ),
              ),
            ),
            // 视频标识
            if (widget.isVideo)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    if (widget.imageUrl.isEmpty) {
      AppToast.error('没有可保存的内容');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (widget.isVideo) {
        final result = await ImageGallerySaverPlus.saveFile(
          response.data,
          name: 'aihuantu_video_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (mounted) {
          setState(() => _isSaving = false);
          if (result['isSuccess'] == true) {
            AppToast.success('视频已保存到相册');
          } else {
            AppToast.error('保存失败');
          }
        }
      } else {
        final result = await ImageGallerySaverPlus.saveImage(
          response.data,
          quality: 100,
          name: 'aihuantu_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (mounted) {
          setState(() => _isSaving = false);
          if (result['isSuccess'] == true) {
            AppToast.success('已保存到相册');
          } else {
            AppToast.error('保存失败');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error('保存失败');
      }
    }
  }
}
