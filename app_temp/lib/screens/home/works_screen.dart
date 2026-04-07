import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'home_screen.dart';
import '../../config/theme.dart';
import '../../models/generation.dart';
import '../../providers/generation_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/share_sheet.dart';
import '../../widgets/muted_autoplay_video_preview.dart';
import '../../widgets/video_player_widget.dart';

/// 作品页面 — iOS 相册风格：日期分组 + 3列网格
class WorksScreen extends StatefulWidget with WidgetsBindingObserver {
  const WorksScreen({super.key});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthService().isLoggedIn) {
        context.read<GenerationProvider>().loadHistory();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 应用从后台恢复时自动刷新
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && AuthService().isLoggedIn) {
      context.read<GenerationProvider>().loadHistory(refresh: true);
      context.read<UserProvider>().loadUserProfile();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<GenerationProvider>().loadHistory(refresh: true);
  }

  /// 按日期分组（降序）
  List<_DateGroup> _groupByDate(List<Generation> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, _DateGroup> groups = {};

    for (final item in items) {
      final createdAt = item.createdAt;
      if (createdAt == null) continue;

      final itemDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

      String title;
      String subtitle;
      String sortKey;

      if (itemDate.isAtSameMomentAs(today) || itemDate.isAfter(today)) {
        title = 'Today';
        subtitle = _monthDay(createdAt);
        sortKey = '0';
      } else if (itemDate.isAtSameMomentAs(yesterday)) {
        title = 'Yesterday';
        subtitle = _monthDay(createdAt);
        sortKey = '1';
      } else {
        title = _monthDay(createdAt);
        subtitle = '${createdAt.year}';
        sortKey = '${itemDate.millisecondsSinceEpoch}';
      }

      groups.putIfAbsent(
        sortKey,
        () => _DateGroup(title: title, subtitle: subtitle, sortKey: sortKey, items: []),
      );
      groups[sortKey]!.items.add(item);
    }

    final sortedKeys = groups.keys.toList()..sort();
    return sortedKeys.map((k) => groups[k]!).toList();
  }

  String _monthDay(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  void _onWorkTap(Generation item) {
    if (item.isCompleted && (item.resultImage?.isNotEmpty ?? false)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ResultPreviewScreen(
            imageUrl: ImageUtils.imgUrl(item.resultImage),
            isVideo: item.isVideo,
          ),
        ),
      );
    } else if (item.isFailed) {
      _showErrorDialog(item);
    }
  }

  Widget _buildLoginGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment(-1, -1), end: Alignment(1, 1),
                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
              ),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          Text('See Your Creations', style: TextStyle(color: context.appColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Sign in to view your face swap history and saved works',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          _buildFeatureCard(Icons.lock_outline, 'Unlimited Swaps', 'No daily limits'),
          const SizedBox(height: 10),
          _buildFeatureCard(Icons.bolt_outlined, 'AI Processing', 'Lightning fast results'),
          const SizedBox(height: 10),
          _buildFeatureCard(Icons.save_outlined, 'Auto Save', 'Works saved automatically'),
          const SizedBox(height: 32),
          Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
            child: MaterialButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/login');
                if (result == true && mounted) {
                  setState(() {});
                  context.read<GenerationProvider>().loadHistory();
                  context.read<UserProvider>().loadUserProfile();
                }
              },
              child: const Text('Sign In to Continue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Free to get started · No credit card required', textAlign: TextAlign.center, style: TextStyle(color: context.appColors.textTertiary, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: context.appColors.cardBackground, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: context.appColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: context.appColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment(-1, -1), end: Alignment(1, 1),
                  colors: [AppTheme.primary.withOpacity(0.15), const Color(0xFF3B82F6).withOpacity(0.15)],
                ),
              ),
              child: Icon(Icons.auto_awesome, color: AppTheme.primary.withOpacity(0.7), size: 36),
            ),
            const SizedBox(height: 20),
            Text('No Works Yet', style: TextStyle(color: context.appColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Try your first face swap now!', style: TextStyle(color: context.appColors.textTertiary, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: 200, height: 48,
              child: MaterialButton(
                onPressed: () => HomeScreen.tabController?.animateTo(0),
                color: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: const Text('Start Creating', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(Generation item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Generation Failed', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(item.errorMessage ?? 'Unknown error, please retry', style: TextStyle(color: context.appColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed title
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              alignment: Alignment.centerLeft,
              child: Text('Works', style: TextStyle(color: context.appColors.textPrimary, fontSize: 34, fontWeight: FontWeight.bold)),
            ),
            // Content
            Expanded(
              child: AuthService().isLoggedIn
                  ? Consumer<GenerationProvider>(
                      builder: (context, provider, _) {
                        // 勿在 history 为空时反复 postFrame loadHistory，否则会无限请求 → 页面闪动。
                        // 首次加载已在 initState / 生命周期中触发。

                        if (provider.isLoading && provider.history.isEmpty) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                        }

                        if (provider.history.isEmpty) {
                          return _buildEmptyState();
                        }

                        final groups = _groupByDate(provider.history);

                        return RefreshIndicator(
                          color: AppTheme.primary,
                          backgroundColor: context.appColors.cardBackground,
                          onRefresh: _onRefresh,
                          child: CustomScrollView(
                            slivers: [
                              for (final group in groups) ...[
                                SliverStickyHeader(
                                  header: Container(
                                    color: context.appColors.background,
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(group.title, style: TextStyle(color: context.appColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                                        if (group.subtitle.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: Text(group.subtitle, style: TextStyle(color: context.appColors.textSecondary, fontSize: 13)),
                                          ),
                                        ],
                                        const Spacer(),
                                        Text('${group.items.length}', style: TextStyle(color: context.appColors.textTertiary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  sliver: SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    sliver: SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 2,
                                        crossAxisSpacing: 2,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => _buildWorkItem(group.items[index]),
                                        childCount: group.items.length,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                            ],
                          ),
                        );
                      },
                    )
                  : _buildLoginGuide(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkItem(Generation item) {
    final resultUrl = ImageUtils.imgUrl(item.resultImage);
    final isSuccess = item.isCompleted;
    final isVideo = item.isVideo;

    return GestureDetector(
      onTap: () => _onWorkTap(item),
      child: Container(
        color: context.appColors.surfaceBackground,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (resultUrl.isNotEmpty)
                isVideo
                    ? MutedAutoplayVideoPreview(url: resultUrl, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: resultUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: context.appColors.surfaceBackground, child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))),
                        errorWidget: (_, __, ___) => Container(color: context.appColors.surfaceBackground, child: Icon(Icons.broken_image, color: context.appColors.textTertiary, size: 32)),
                      ),

              // Video icon
              if (isVideo)
                Positioned(
                  bottom: 6, left: 6,
                  child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.play_arrow, color: Colors.white, size: 13)),
                  ),
                ),

              // Status badge
              Positioned(
                top: 4, right: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(isSuccess ? '✓' : '✕', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateGroup {
  final String title;
  final String subtitle;
  final String sortKey;
  final List<Generation> items;
  const _DateGroup({required this.title, required this.subtitle, required this.sortKey, required this.items});
}

/// 全屏预览（支持保存+分享）
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => ShareSheet.show(context),
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download, color: Colors.white),
            onPressed: _isSaving ? null : _saveToGallery,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: widget.isVideo
            ? AppVideoPlayer(url: widget.imageUrl)
            : InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  errorWidget: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: context.appColors.textTertiary, size: 48)),
                ),
              ),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    if (widget.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No content to save')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dio = Dio();
      final response = await dio.get(widget.imageUrl, options: Options(responseType: ResponseType.bytes));
      if (widget.isVideo) {
        // 视频需要先保存到临时文件，再用 saveFile 保存到相册
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await tempFile.writeAsBytes(response.data);
        final result = await ImageGallerySaverPlus.saveFile(tempFile.path, name: 'aihuantu_video_${DateTime.now().millisecondsSinceEpoch}');
        // 清理临时文件
        if (await tempFile.exists()) await tempFile.delete();
        if (mounted) {
          setState(() => _isSaving = false);
          if (result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video saved to gallery')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed')));
          }
        }
      } else {
        final result = await ImageGallerySaverPlus.saveImage(response.data, quality: 100, name: 'aihuantu_${DateTime.now().millisecondsSinceEpoch}');
        if (mounted) {
          setState(() => _isSaving = false);
          if (result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to gallery')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${e.toString()}')));
      }
    }
  }
}
