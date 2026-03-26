import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../utils/image_utils.dart';
import '../../widgets/template_card.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = ImageUtils.imgUrl(widget.template.cover);

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
              child: PageView.builder(
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
                    widget.template.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // 使用次数
                  if (widget.template.useCount != null) ...[
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
                          '${widget.template.useCount}人使用',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // 描述
                  if (widget.template.description != null &&
                      widget.template.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.template.description!,
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
                onTap: () {},
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.template.isFavorite ?? false
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.template.isFavorite ?? false
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
                      Navigator.of(context).pop({'templateId': widget.template.id});
                    },
                    child: const Text(
                      '立即使用',
                      style: TextStyle(
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
