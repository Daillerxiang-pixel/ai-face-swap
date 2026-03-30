import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Theme state management
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  final ApiService _api = ApiService();

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  // Dynamic colors based on current theme
  Color get background => _isDark ? AppTheme.background : AppTheme.lightBackground;
  Color get cardBackground => _isDark ? AppTheme.cardBackground : AppTheme.lightCardBackground;
  Color get surfaceBackground => _isDark ? AppTheme.surfaceBackground : AppTheme.lightSurfaceBackground;
  Color get textPrimary => _isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color get textSecondary => _isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color get textTertiary => _isDark ? AppTheme.textTertiary : AppTheme.lightTextTertiary;

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