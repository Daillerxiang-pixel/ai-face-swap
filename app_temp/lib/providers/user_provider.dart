import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// 用户状态管理
class UserProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  /// 当前用户
  User? _user;

  /// 是否正在加载
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isVip => _user?.isVip ?? false;
  int get remainCredits => _user?.remainCredits ?? 0;

  /// 加载用户信息
  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getUserProfile().timeout(const Duration(seconds: 5));
      if (res.success && res.data != null) {
        _user = User.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // API 请求失败 → 视为未登录
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 退出登录
  void logout() {
    _user = null;
    notifyListeners();
  }
}
