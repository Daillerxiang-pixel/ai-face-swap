import 'package:shared_preferences/shared_preferences.dart';

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

  /// 从本地恢复 Token
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('auth_user_id');
  }

  /// 持久化到本地
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user_id', _userId ?? '');
    } else {
      await prefs.remove('auth_token');
      await prefs.remove('auth_user_id');
    }
  }
}
