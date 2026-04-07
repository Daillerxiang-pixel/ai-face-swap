import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../utils/auth_gate.dart';
import '../../models/template.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/surface_video_preview.dart';
import '../../widgets/toast.dart';
import '../profile/vip_purchase_screen.dart';
import 'result_screen.dart';

/// 上传照片页面 — 选择模板后上传照片
class UploadPhotoScreen extends StatefulWidget {
  final Template template;

  const UploadPhotoScreen({super.key, required this.template});

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  /// 用户选择的本地图片
  File? _selectedImage;

  /// 上传状态
  bool _isUploading = false;
  bool _isGenerating = false;

  /// 上传后获得的 fileId
  String? _fileId;

  /// 生成结果
  String? _generationId;
  String? _status;
  String? _resultUrl;
  String? _errorMsg;
  int _progress = 0;

  /// 轮询定时器
  int _pollCount = 0;
  static const _maxPolls = AppConfig.maxWaitSeconds ~/ 3; // 40 polls × 3s

  Template get _template => widget.template;
  bool get _isVideo => _template.isVideoWorkflow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!AuthService().isLoggedIn) {
        final ok = await ensureLoggedInForCreate(context);
        if (!mounted) return;
        if (!ok || !AuthService().isLoggedIn) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
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
      ),
      body: _isGenerating
          ? _buildGeneratingView()
          : Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 模板预览
                        _buildTemplatePreview(),
                        const SizedBox(height: 24),

                        // 上传照片区域
                        _buildUploadArea(),
                        const SizedBox(height: 24),

                        // 提示文字
                        _buildTips(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Fixed bottom button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  decoration: BoxDecoration(
                    color: context.appColors.background,
                  ),
                  child: _buildGenerateButton(),
                ),
              ],
            ),
    );
  }

  /// 模板预览
  Widget _buildTemplatePreview() {
    final previewUrl = ImageUtils.imgUrl(_template.displayUrl);
    final videoRaw = _template.videoPlaybackSource;
    final videoFull =
        videoRaw != null && videoRaw.isNotEmpty ? ImageUtils.imgUrl(videoRaw) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template Preview',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          width: double.infinity,
          child: videoFull.isNotEmpty
              ? SurfaceVideoPreview(
                  url: videoFull,
                  height: 200,
                  borderRadius: BorderRadius.circular(16),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (previewUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: previewUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: context.appColors.surfaceBackground,
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: AppTheme.textTertiary, size: 48),
                          ),
                        )
                      else
                        Container(
                          color: context.appColors.surfaceBackground,
                          child: const Icon(Icons.auto_awesome,
                              color: AppTheme.textTertiary, size: 48),
                        ),
                      if (_isVideo)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white, size: 24),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  /// 上传照片区域
  Widget _buildUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Photo',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedImage != null
                    ? AppTheme.primary
                    : context.appColors.surfaceBackground,
                width: 1.5,
              ),
            ),
            child: _isUploading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Uploading...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              color: context.appColors.surfaceBackground,
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // 重新选择按钮
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          // 上传成功标记
                          if (_fileId != null)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 3),
                                    Text(
                                      'Uploaded',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: context.appColors.textTertiary,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to select a photo',
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supports JPG / PNG / WEBP',
                              style: TextStyle(
                                color: context.appColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  /// 提示
  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isVideo ? Icons.videocam_outlined : Icons.lightbulb_outline,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isVideo
                  ? 'Video face swap takes 1-3 minutes. For best results, use a clear, front-facing photo with good lighting.'
                  : 'For best results, use a clear, front-facing photo with good lighting.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 生成按钮
  Widget _buildGenerateButton() {
    final canGenerate = _selectedImage != null && _fileId != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: canGenerate ? AppTheme.primaryGradient : null,
          color: canGenerate ? null : context.appColors.surfaceBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: MaterialButton(
          onPressed: canGenerate ? _startGenerate : null,
          disabledColor: Colors.transparent,
          child: Text(
            _isVideo ? 'Start Video Swap' : 'Start Swap',
            style: TextStyle(
              color: canGenerate
                  ? context.appColors.textPrimary
                  : context.appColors.textTertiary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 生成中视图
  Widget _buildGeneratingView() {
    final isFailed = _status == 'failed';
    final isCompleted = _status == 'completed';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 动画
            if (isFailed)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF3B30),
                  size: 40,
                ),
              )
            else
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _progress / 100,
                        strokeWidth: 4,
                        backgroundColor: context.appColors.surfaceBackground,
                        color: AppTheme.primary,
                      ),
                    ),
                    Icon(
                      _isVideo ? Icons.videocam : Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // 状态文字
            Text(
              _getProgressText(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // 进度百分比 / 错误信息
            if (isFailed)
              Text(
                _errorMsg ?? 'Generation failed, please retry',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                '$_progress%',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 32),

            // 按钮
            if (isFailed)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.appColors.textTertiary),
                        foregroundColor: context.appColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startGenerate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: context.appColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.appColors.textTertiary),
                    foregroundColor: context.appColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 获取进度提示文字
  String _getProgressText() {
    switch (_status) {
      case 'completed':
        return _isVideo ? 'Video complete!' : 'Swap complete!';
      case 'failed':
        return 'Generation failed';
      default:
        if (_progress < 10) return 'Submitting...';
        if (_progress < 50) return _isVideo ? 'Processing video...' : 'AI is analyzing...';
        if (_progress < 90) return _isVideo ? 'Compositing video...' : 'Generating...';
        return _isVideo ? 'Almost done...' : 'Almost there...';
    }
  }

  /// 选择照片
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Photo',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
                title: Text('Camera', style: TextStyle(color: context.appColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: Text('Photo Library', style: TextStyle(color: context.appColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
        _fileId = null; // 重置上传状态
      });

      // 自动上传
      _uploadImage(image.path);
    } catch (e) {
      AppToast.error('Failed to select photo');
    }
  }

  /// 上传照片到服务器
  Future<void> _uploadImage(String filePath) async {
    setState(() => _isUploading = true);

    try {
      final res = await _api.uploadImage(filePath);
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final fileId = data['fileId'] as String;
        if (mounted) {
          setState(() {
            _fileId = fileId;
            _isUploading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isUploading = false);
        }
        AppToast.error(res.message ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
      }
      AppToast.error('Upload failed, check network');
    }
  }

  /// 提交生成任务
  Future<void> _startGenerate({bool isRetry = false}) async {
    if (_fileId == null) {
      AppToast.warning('Please upload a photo first');
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'processing';
      _progress = 5;
      _errorMsg = null;
      _resultUrl = null;
      _pollCount = 0;
    });

    try {
      final res = await _api.createGeneration(
        templateId: _template.id,
        sourceFileId: _fileId!,
      );

      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _generationId = data['generationId'] as String?;
        final genStatus = data['status'] as String?;
        _progress = (data['progress'] as int?) ?? 10;
        final async = data['async'] as bool? ?? false;

        // 同步完成
        if (genStatus == 'completed' && !async) {
          final resultUrl = data['resultUrl'] as String?;
          if (resultUrl != null && resultUrl.isNotEmpty) {
            setState(() {
              _status = 'completed';
              _progress = 100;
              _resultUrl = resultUrl;
            });
            _onGenerateComplete();
            return;
          }
        }

        // 失败
        if (genStatus == 'failed') {
          setState(() {
            _status = 'failed';
            _errorMsg = data['error'] as String?;
          });
          return;
        }

        // 异步 → 开始轮询
        if (mounted) {
          setState(() {
            _status = genStatus ?? 'processing';
          });
          _startPolling();
        }
      } else {
        // 检查是否是次数不足
        if (res.errorCode == 'QUOTA_EXCEEDED') {
          _showQuotaExceededDialog();
        } else {
          final msg = res.message ?? '';
          if (!isRetry &&
              isAuthErrorMessage(msg) &&
              mounted) {
            final ok = await ensureLoggedInForCreate(context);
            if (ok && mounted && AuthService().isLoggedIn) {
              await _startGenerate(isRetry: true);
              return;
            }
          }
          setState(() {
            _status = 'failed';
            _errorMsg = msg.isNotEmpty ? msg : 'Failed to submit task';
          });
        }
      }
    } catch (e) {
      String msg = 'Network error, please retry';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final err = data['error'] ?? data['message'];
          if (err != null) msg = err.toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          msg = e.message!;
        }
        if (e.response?.statusCode == 401) {
          if (!isRetry && mounted) {
            final ok = await ensureLoggedInForCreate(context);
            if (ok && mounted && AuthService().isLoggedIn) {
              await _startGenerate(isRetry: true);
              return;
            }
          }
          msg = 'Please sign in and try again.';
        }
      }
      setState(() {
        _status = 'failed';
        _errorMsg = msg;
      });
    }
  }

  /// 显示次数不足弹窗
  void _showQuotaExceededDialog() {
    setState(() {
      _isGenerating = false;
      _status = 'failed';
      _errorMsg = 'Monthly quota exceeded';
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Quota Exceeded',
          style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              'Your monthly generation quota has been used up.\n\nUpgrade to VIP for unlimited generations!',
              style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.appColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 跳转到 VIP 购买页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VipPurchaseScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upgrade VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// 轮询生成状态
  void _startPolling() {
    Future.delayed(const Duration(milliseconds: AppConfig.pollInterval), () async {
      if (!mounted || _generationId == null) return;
      if (_status == 'completed' || _status == 'failed') return;

      _pollCount++;
      if (_pollCount > _maxPolls) {
        setState(() {
          _status = 'failed';
          _errorMsg = 'Generation timed out';
        });
        return;
      }

      try {
        final res = await _api.getGenerationStatus(_generationId!);
        if (res.success && res.data != null) {
          final data = res.data as Map<String, dynamic>;
          final newStatus = data['status'] as String?;
          final newProgress = (data['progress'] as int?) ?? 0;
          final resultUrl = data['resultUrl'] as String?;
          final error = data['error'] as String?;

          if (mounted) {
            setState(() {
              _status = newStatus ?? 'processing';
              _progress = newProgress;
              if (resultUrl != null) _resultUrl = resultUrl;
              if (error != null) _errorMsg = error;
            });
          }

          if (newStatus == 'completed') {
            _onGenerateComplete();
            return;
          }

          if (newStatus == 'failed') {
            return; // 停止轮询
          }
        }
      } catch (_) {
        // 网络错误继续轮询
      }

      // 继续轮询
      if (mounted && _status != 'completed' && _status != 'failed') {
        _startPolling();
      }
    });
  }

  /// 生成完成 → 跳转结果页
  void _onGenerateComplete() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            resultUrl: _resultUrl ?? '',
            templateType: _template.type,
            templateName: _template.name,
          ),
        ),
      );
    });
  }
}
