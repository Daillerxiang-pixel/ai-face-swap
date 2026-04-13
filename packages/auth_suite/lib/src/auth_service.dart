import 'package:shared_preferences/shared_preferences.dart';

/// 用户认证与 Token 管理（按 [keyPrefix] 隔离，多 App 共用同一套 API 时 token 互不覆盖）
class AuthService {
  AuthService._(this._keyPrefix);

  /// 存储键前缀，例如 `''`（默认 `auth_token`）、`photokit_`
  final String _keyPrefix;

  static final Map<String, AuthService> _instances = {};

  /// [keyPrefix] 相同则返回同一实例，便于在 App 内注入
  factory AuthService({String keyPrefix = ''}) {
    return _instances.putIfAbsent(keyPrefix, () => AuthService._(keyPrefix));
  }

  String _k(String name) => '$_keyPrefix$name';

  String? _token;
  String? _userId;

  /// 当前 Token
  String? get token => _token;

  /// 当前用户 ID
  String? get userId => _userId;

  /// 是否已登录
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 设置 Token
  void setToken(String token, {String? userId}) {
    _token = token;
    if (userId != null) _userId = userId;
    _persist();
  }

  /// 清除 Token
  void clearToken() {
    _token = null;
    _userId = null;
    _persist();
  }

  /// 从本地恢复 Token（应用启动时调用）
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_k('auth_token'));
    _userId = prefs.getString(_k('auth_user_id'));
  }

  /// 持久化到本地
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_k('auth_token'), _token!);
      await prefs.setString(_k('auth_user_id'), _userId ?? '');
    } else {
      await prefs.remove(_k('auth_token'));
      await prefs.remove(_k('auth_user_id'));
    }
  }
}
