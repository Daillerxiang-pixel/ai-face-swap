import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/template.dart';
import 'template_media_thumb.dart';

/// 模板卡片组件
class TemplateCard extends StatelessWidget {
  final Template template;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showInfo;

  const TemplateCard({
    super.key,
    required this.template,
    this.width,
    this.height,
    this.onTap,
    this.onFavorite,
    this.showInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = template.isVideoWorkflow;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片区域
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TemplateMediaThumb(template: template, fit: BoxFit.cover),

                  // 视频播放图标
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

                  // 使用次数角标
                  if (template.useCount != null)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.remove_red_eye_outlined,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatCount(template.useCount!),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // 收藏按钮
                  if (onFavorite != null)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: GestureDetector(
                        onTap: onFavorite,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            template.isFavorite ?? false
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: template.isFavorite ?? false
                                ? Colors.redAccent
                                : Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 标题信息
          if (showInfo && template.name.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: width,
              child: Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 格式化使用次数
  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
