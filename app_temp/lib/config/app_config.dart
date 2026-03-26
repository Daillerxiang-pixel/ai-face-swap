/// 应用全局配置常量
class AppConfig {
  AppConfig._();

  /// API 基础地址
  static const String apiBaseUrl = 'http://39.102.100.123:8080';

  /// OSS 图片基础地址
  static const String ossBaseUrl = 'https://aihuantu.oss-cn-beijing.aliyuncs.com';

  /// 模拟用户ID（开发阶段使用）
  static const String mockUserId = 'user-mock-001';

  /// 每页加载数量
  static const int pageSize = 20;

  /// 生成结果轮询间隔（毫秒）
  static const int pollInterval = 3000;

  /// 生成结果最大等待时间（秒）
  static const int maxWaitSeconds = 120;
}
