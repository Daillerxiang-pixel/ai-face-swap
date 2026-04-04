/// 应用全局配置常量
class AppConfig {
  AppConfig._();

  /// API 基础地址
  ///
  /// 构建时可通过 `--dart-define=API_BASE=https://test1.kanashortplay.com` 指向测试服；
  /// 未传入时默认为正式接口域名。
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'https://test.kanashortplay.com';
  }

  /// OSS 图片基础地址
  static const String ossBaseUrl = 'https://aihuantu.oss-cn-beijing.aliyuncs.com';

  /// 每页加载数量
  static const int pageSize = 20;

  /// 弱网 / VPN：与主工程 app 对齐
  static const Duration apiConnectTimeout = Duration(seconds: 45);
  static const Duration apiReceiveTimeout = Duration(seconds: 90);
  static const Duration apiSendTimeout = Duration(seconds: 120);

  /// 生成结果轮询间隔（毫秒）
  static const int pollInterval = 4000;

  /// 生成结果最大等待时间（秒）
  /// 图片换脸较快（~30秒），视频换脸较慢（~3-5分钟）
  /// 默认 300 秒（5分钟）
  static const int maxWaitSeconds = 300;
}
