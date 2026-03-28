import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../utils/image_utils.dart';
import '../../providers/template_provider.dart';
import '../../widgets/share_sheet.dart';
import '../create/upload_photo_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 模板详情页面
class TemplateDetailScreen extends StatefulWidget {
  final Template template;

  const TemplateDetailScreen({super.key, required this.template});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  late Template _template;

  /// 视频播放器控制器
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;
  bool _showPlayOverlay = true;

  @override
  void initState() {
    super.initState();
    _template = widget.template;
    if (_template.isVideo && _template.videoUrl != null && _template.videoUrl!.isNotEmpty) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    final videoUrl = ImageUtils.imgUrl(_template.videoUrl!);
    if (videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
      });
      // 循环播放
      controller.setLooping(true);
      // 播放结束或出错时回到封面状态
      controller.addListener(_videoListener);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVideoError = true;
      });
    }
  }

  void _videoListener() {
    final ctrl = _videoController;
    if (ctrl == null || !mounted) return;

    if (ctrl.value.hasError) {
      setState(() {
        _isVideoError = true;
        _showPlayOverlay = true;
      });
    }
  }

  void _togglePlayPause() {
    final ctrl = _videoController;
    if (ctrl == null || !_isVideoInitialized) return;

    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
        _showPlayOverlay = true;
      } else {
        ctrl.play();
        _showPlayOverlay = false;
      }
    });
  }

  void _resetToCover() {
    final ctrl = _videoController;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
      ctrl.seekTo(Duration.zero);
    }
    setState(() {
      _showPlayOverlay = true;
    });
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = ImageUtils.imgUrl(_template.displayUrl);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ShareSheet.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模板预览区域
            AspectRatio(
              aspectRatio: 3 / 4,
              child: _buildPreviewArea(coverUrl),
            ),
            // 信息区域
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 模板名称
                  Text(
                    _template.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // 使用次数
                  if (_template.useCount != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_template.useCount} uses',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // 描述
                  if (_template.description != null &&
                      _template.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _template.description!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // 底部操作按钮
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
          ),
          child: Row(
            children: [
              // 收藏按钮
              GestureDetector(
                onTap: () {
                  context.read<TemplateProvider>().toggleFavorite(_template.id);
                  setState(() {
                    _template = Template(
                      id: _template.id,
                      name: _template.name,
                      cover: _template.cover,
                      preview: _template.preview,
                      previewUrl: _template.previewUrl,
                      videoUrl: _template.videoUrl,
                      category: _template.category,
                      scene: _template.scene,
                      type: _template.type,
                      useCount: _template.useCount,
                      isFavorite: !(_template.isFavorite ?? false),
                      description: _template.description,
                      icon: _template.icon,
                      bg: _template.bg,
                      usage: _template.usage,
                      usageNum: _template.usageNum,
                      badge: _template.badge,
                      rating: _template.rating,
                      provider: _template.provider,
                      createdAt: _template.createdAt,
                    );
                  });
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _template.isFavorite ?? false
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _template.isFavorite ?? false
                        ? Colors.redAccent
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 使用按钮
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: MaterialButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UploadPhotoScreen(template: _template),
                        ),
                      );
                    },
                    child: Text(
                      _template.isVideo ? 'Video Template' : 'Use Template',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  /// 构建预览区域（图片 / 视频）
  Widget _buildPreviewArea(String coverUrl) {
    // 非视频模板：直接显示图片
    if (!_template.isVideo) {
      return _buildImagePreview(coverUrl);
    }

    // 视频模板：显示封面 + 可播放视频
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频播放器（已初始化且正在播放时显示）
          if (_isVideoInitialized && !_showPlayOverlay)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),

          // 封面图（未播放时显示）
          if (!_isVideoInitialized || _showPlayOverlay)
            _buildImagePreview(coverUrl),

          // 视频加载中指示器
          if (_template.isVideo && !_isVideoInitialized && !_isVideoError)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // 播放/暂停按钮覆盖层
          if (_template.isVideo && (_showPlayOverlay || _isVideoError))
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: Icon(
                  _isVideoError
                      ? Icons.play_circle_outline
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),

          // 视频标识标签
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isVideoInitialized && !_showPlayOverlay
                        ? Icons.pause_circle_filled
                        : Icons.videocam,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Video',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 图片预览
  Widget _buildImagePreview(String coverUrl) {
    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.surfaceBackground,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.surfaceBackground,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppTheme.textTertiary,
          size: 48,
        ),
      ),
    );
  }
}
