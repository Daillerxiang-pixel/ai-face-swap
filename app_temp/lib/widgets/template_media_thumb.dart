import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/template.dart';
import '../utils/image_utils.dart';
import '../utils/media_url_utils.dart';
import 'muted_autoplay_video_preview.dart';

/// List/grid thumbnail: use a **static image** (poster) when possible to avoid decoding many videos.
/// Set [allowMutedVideo] true only where a looping silent preview is desired (rare).
class TemplateMediaThumb extends StatelessWidget {
  final Template template;
  final BoxFit fit;
  final bool allowMutedVideo;

  const TemplateMediaThumb({
    super.key,
    required this.template,
    this.fit = BoxFit.cover,
    this.allowMutedVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (allowMutedVideo) {
      final videoSrc = template.videoPlaybackSource;
      if (videoSrc != null && videoSrc.isNotEmpty) {
        final u = ImageUtils.imgUrl(videoSrc);
        if (u.isNotEmpty) {
          return MutedAutoplayVideoPreview(url: u, fit: fit);
        }
      }
    }

    final thumb = template.thumbnailImageUrl;
    final imageUrl = ImageUtils.imgUrl(thumb);
    if (imageUrl.isNotEmpty) {
      return _networkThumb(
        context,
        imageUrl,
        errorAsVideo: template.isVideoWorkflow,
      );
    }

    if (template.isVideoWorkflow) {
      return _videoPlaceholder(context, true);
    }

    final du = template.displayUrl;
    final fallback = ImageUtils.imgUrl(du);
    if (fallback.isNotEmpty && !MediaUrlUtils.looksLikeVideoPath(du)) {
      return _networkThumb(
        context,
        fallback,
        errorAsVideo: template.isVideoWorkflow,
      );
    }

    return _videoPlaceholder(context, template.isVideoWorkflow);
  }

  /// GIF must not use [CachedNetworkImage] + Octo fade (and must not sit under
  /// [Opacity]); use [Image] + [CachedNetworkImageProvider] so multi-frame decode runs.
  Widget _networkThumb(
    BuildContext context,
    String imageUrl, {
    required bool errorAsVideo,
  }) {
    if (MediaUrlUtils.looksLikeGifPath(imageUrl)) {
      return Image(
        image: CachedNetworkImageProvider(imageUrl),
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return Container(
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
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _videoPlaceholder(context, errorAsVideo),
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
      errorWidget: (context, url, error) =>
          _videoPlaceholder(context, errorAsVideo),
    );
  }

  Widget _videoPlaceholder(BuildContext context, bool isVideo) {
    return ColoredBox(
      color: context.appColors.surfaceBackground,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_outlined : Icons.image_not_supported_outlined,
          color: context.appColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}
