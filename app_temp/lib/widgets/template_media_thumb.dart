import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/template.dart';
import '../utils/image_utils.dart';
import 'muted_autoplay_video_preview.dart';

/// 模板缩略：有视频源时用静音循环视频，否则用封面图（避免把 mp4 当图片加载失败）
class TemplateMediaThumb extends StatelessWidget {
  final Template template;
  final BoxFit fit;

  const TemplateMediaThumb({
    super.key,
    required this.template,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final videoSrc = template.videoPlaybackSource;
    if (videoSrc != null && videoSrc.isNotEmpty) {
      final u = ImageUtils.imgUrl(videoSrc);
      if (u.isNotEmpty) {
        return MutedAutoplayVideoPreview(url: u, fit: fit);
      }
    }

    final imageUrl = ImageUtils.imgUrl(template.displayUrl);
    if (imageUrl.isEmpty) {
      return ColoredBox(
        color: context.appColors.surfaceBackground,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: context.appColors.textTertiary,
          size: 32,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => Container(
        color: context.appColors.surfaceBackground,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: context.appColors.surfaceBackground,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: context.appColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}
