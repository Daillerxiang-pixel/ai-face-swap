import '../config/app_config.dart';

/// 用户认证与 Token 管理
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  String? _token;
  String? _userId;

  /// 当前 Token
  String? get token => _token;

  /// 当前用户ID
  String get userId => _userId ?? AppConfig.mockUserId;

  /// 是否已登录
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 设置 Token
  void setToken(String token, {String? userId}) {
    _token = token;
    if (userId != null) _userId = userId;
  }

  /// 清除 Token
  void clearToken() {
    _token = null;
    _userId = null;
  }
}
