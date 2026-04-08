/// 判断路径/URL 是否像视频文件（用于模板预览 mp4、作品结果 mp4 等）
class MediaUrlUtils {
  MediaUrlUtils._();

  static bool looksLikeVideoPath(String? path) {
    if (path == null || path.isEmpty) return false;
    final base = path.split('?').first.trim().toLowerCase();
    return base.endsWith('.mp4') ||
        base.endsWith('.mov') ||
        base.endsWith('.webm') ||
        base.endsWith('.m4v') ||
        base.endsWith('.avi');
  }

  /// Animated GIF poster/cover (query string stripped before extension check).
  static bool looksLikeGifPath(String? path) {
    if (path == null || path.isEmpty) return false;
    final base = path.split('?').first.trim().toLowerCase();
    return base.endsWith('.gif');
  }
}
