import 'package:flutter/foundation.dart';

/// 用户状态管理基类
///
/// 具体项目继承此类，注入自己的 User 模型和 API 调用。
/// 提供通用的登录状态管理、加载状态、登出逻辑。
abstract class AuthProvider<T> with ChangeNotifier {
  /// 当前用户数据
  T? _user;
  bool _isLoading = false;

  T? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  set user(T? value) {
    _user = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 子类实现 —— 从后端加载用户信息
  Future<void> fetchUserProfile();

  /// 加载用户信息（带 loading 状态）
  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      await fetchUserProfile();
    } catch (_) {
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
