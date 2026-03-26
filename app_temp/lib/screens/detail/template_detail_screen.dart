import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../utils/image_utils.dart';
import '../../providers/template_provider.dart';
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
  late PageController _pageController;
  int _currentPage = 0;
  late Template _template;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _template = widget.template;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = ImageUtils.imgUrl(_template.displayUrl);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('模板详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模板预览图
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: 1,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, _) {
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
                    },
                  ),
                  // 视频标识
                  if (_template.isVideo)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      ),
                    ),
                ],
              ),
            ),
            // 页码指示器
            const SizedBox(height: 12),
            Center(
              child: Text(
                '1/1',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            // 信息区域
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
                          '${_template.useCount}人使用',
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
                      _template.isVideo ? '视频换脸' : '立即使用',
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
}
