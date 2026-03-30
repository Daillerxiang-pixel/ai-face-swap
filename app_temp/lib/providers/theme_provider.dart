import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Theme state management
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  final ApiService _api = ApiService();

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void initFromUser(String? userTheme) {
    _isDark = userTheme != 'light';
    notifyListeners();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
    _saveToServer();
  }

  void setTheme(bool isDark) {
    if (_isDark == isDark) return;
    _isDark = isDark;
    notifyListeners();
    _saveToServer();
  }

  void _saveToServer() {
    _api.updateUserSettings(theme: _isDark ? 'dark' : 'light').catchError((_) {});
  }
}