/// 应用全局配置常量
class AppConfig {
  AppConfig._();

  /// API 根地址（**仅由构建时 `dart-define` 决定**；**不要**为测试/正式建 Git 分支）。
  ///
  /// - **日常 / 测试包**：不传 `API_BASE` → 默认 `https://test1.kanashortplay.com`
  /// - **正式包（APK / IPA）**：  
  ///   `--dart-define=API_BASE=https://api.deepfaceswap.tech`
  ///
  /// 与服务端同一套仓库；环境差异只在部署与构建参数，不在客户端分分支。
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'https://test1.kanashortplay.com';
  }

  /// 后端 `users.app_code`：与 PhotoKit 等共用 API 时隔离账号；FaceSwap 默认 `faceswap`
  static const String clientApp =
      String.fromEnvironment('CLIENT_APP', defaultValue: 'faceswap');

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
