import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/toast.dart';
import 'select_template_screen.dart';

/// 生成结果展示页面
class ResultScreen extends StatefulWidget {
  final String resultUrl;
  final String? templateType; // 'image' or 'video'
  final String? templateName;

  const ResultScreen({
    super.key,
    required this.resultUrl,
    this.templateType,
    this.templateName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ApiService _api = ApiService();

  bool _isSaving = false;
  bool _isDownloading = false;

  bool get _isVideo => widget.templateType == 'video';
  String get _displayUrl => ImageUtils.imgUrl(widget.resultUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('生成结果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              AppToast.info('分享功能开发中');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 结果展示区域
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildResultView(),
                ),
              ),
            ),
          ),

          // 底部操作区
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D),
              border: Border(
                top: BorderSide(
                  color: AppTheme.surfaceBackground,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // 保存按钮
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _saveToGallery,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: Text(
                          _isVideo ? '保存视频' : '保存图片',
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 再来一次
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SelectTemplateScreen(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text(
                          '再来一次',
                          style: TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建结果展示
  Widget _buildResultView() {
    if (_displayUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.cardBackground,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: AppTheme.textTertiary, size: 64),
            SizedBox(height: 16),
            Text(
              '结果图片加载失败',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_isVideo) {
      // 视频：显示第一帧 + 播放标识
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _displayUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: AppTheme.surfaceBackground,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: AppTheme.surfaceBackground,
              child: const Icon(Icons.broken_image,
                  color: AppTheme.textTertiary, size: 48),
            ),
          ),
          // 视频标识
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ),
          // 视频标签
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '视频结果',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 图片：全屏展示
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: CachedNetworkImage(
        imageUrl: _displayUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => Container(
          color: AppTheme.surfaceBackground,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppTheme.surfaceBackground,
          child: const Icon(Icons.broken_image,
              color: AppTheme.textTertiary, size: 48),
        ),
      ),
    );
  }

  /// 保存到相册
  Future<void> _saveToGallery() async {
    if (_displayUrl.isEmpty) {
      AppToast.error('没有可保存的内容');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 下载文件
      final dio = Dio();
      final response = await dio.get(
        _displayUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (_isVideo) {
        // 视频文件保存
        final result = await ImageGallerySaverPlus.saveFile(
          response.data,
          name: 'aihuantu_video_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          setState(() => _isSaving = false);
          final isSuccess = result['isSuccess'] == true;
          if (isSuccess) {
            AppToast.success('视频已保存到相册');
          } else {
            AppToast.error('保存失败，请检查相册权限');
          }
        }
      } else {
        // 图片保存
        final result = await ImageGallerySaverPlus.saveImage(
          response.data,
          quality: 100,
          name: 'aihuantu_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          setState(() => _isSaving = false);
          final isSuccess = result['isSuccess'] == true;
          if (isSuccess) {
            AppToast.success('已保存到相册');
          } else {
            AppToast.error('保存失败，请检查相册权限');
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
