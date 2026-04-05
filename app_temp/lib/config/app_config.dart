/// 应用全局配置常量
class AppConfig {
  AppConfig._();

  /// API 基础地址（**仅由客户端构建时决定环境**，与服务端是否测试/正式无关）。
  ///
  /// **推荐做法（两套 APK，服务端同一套代码）：**
  /// - **测试包**：不设 `API_BASE` 或设为测试 API → 默认 `https://test1.kanashortplay.com`
  /// - **正式包**：构建时必带  
  ///   `--dart-define=API_BASE=https://test.kanashortplay.com`
  ///
  /// 服务端部署测试机 / 正式机时仍用**同一 Git 仓库**；差异只在各机 `server/.env` 与 Nginx，不在 Flutter 里写死「环境名」。
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'https://test1.kanashortplay.com';
  }

  /// 与 [apiBaseUrl] 无关：OSS 公网 Bucket 基址，用于相对路径拼 URL（与后端、控制台 Bucket 一致即可）
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
