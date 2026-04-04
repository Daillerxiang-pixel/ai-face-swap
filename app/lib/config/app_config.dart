/// 应用全局配置常量
class AppConfig {
  AppConfig._();

  /// API 基础地址（构建：`--dart-define=API_BASE=...` 可指向测试服 test1）
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'https://test.kanashortplay.com';
  }

  /// OSS 图片基础地址
  static const String ossBaseUrl = 'https://aihuantu.oss-cn-beijing.aliyuncs.com';

  /// 模拟用户ID（开发阶段使用）
  static const String mockUserId = 'user-mock-001';

  /// 每页加载数量
  static const int pageSize = 20;

  /// HTTP 连接超时（跨境 / VPN 时握手与路由较慢，不宜过短）
  static const Duration apiConnectTimeout = Duration(seconds: 45);

  /// 读超时（列表、生成状态等）
  static const Duration apiReceiveTimeout = Duration(seconds: 90);

  /// 写超时（上传图片等较大请求）
  static const Duration apiSendTimeout = Duration(seconds: 120);

  /// 弱网时对连接/读超时自动重试次数（不含首次请求）
  static const int apiRetryCount = 2;

  /// 生成结果轮询间隔（毫秒；弱网时可略拉长，减轻并发压力）
  static const int pollInterval = 4000;

  /// 生成结果最大等待时间（秒）
  static const int maxWaitSeconds = 300;
}
