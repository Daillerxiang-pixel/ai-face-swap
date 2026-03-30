/// 应用全局配置常量
class AppConfig {
  AppConfig._();

  /// API 基础地址
  static const String apiBaseUrl = 'https://test.kanashortplay.com';

  /// OSS 图片基础地址
  static const String ossBaseUrl = 'https://aihuantu.oss-cn-beijing.aliyuncs.com';

  /// 每页加载数量
  static const int pageSize = 20;

  /// 生成结果轮询间隔（毫秒）
  static const int pollInterval = 3000;

  /// 生成结果最大等待时间（秒）
  /// 图片换脸较快（~30秒），视频换脸较慢（~3-5分钟）
  /// 默认 300 秒（5分钟）
  static const int maxWaitSeconds = 300;
}
