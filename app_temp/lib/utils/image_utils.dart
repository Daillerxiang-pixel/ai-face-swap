import '../config/app_config.dart';

/// 图片路径处理工具
class ImageUtils {
  ImageUtils._();

  /// 将相对路径转为完整图片URL
  ///
  /// 后端未接 OSS 时多为 `/uploads/...`，须走 **API 同域**（与 [AppConfig.apiBaseUrl] 一致），
  /// 不能拼到 [AppConfig.ossBaseUrl]，否则模板预览、本地上传结果图会 404。
  static String imgUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      return '${AppConfig.apiBaseUrl}$path';
    }
    return '${AppConfig.ossBaseUrl}/$path';
  }

  /// 获取缩略图URL（OSS 图片缩放参数）
  static String thumbnailUrl(String? path, {int width = 200}) {
    final fullUrl = imgUrl(path);
    if (fullUrl.isEmpty) return '';
    // 如果是 OSS 图片，添加缩放参数
    if (fullUrl.contains('aliyuncs.com')) {
      return '$fullUrl?x-oss-process=image/resize,w_$width';
    }
    return fullUrl;
  }
}
