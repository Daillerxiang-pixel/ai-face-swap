import 'package:flutter/material.dart';

/// 应用暗黑主题配置（iOS 风格）
class AppTheme {
  AppTheme._();

  // ===== 颜色 =====
  /// 主背景色（body）
  static const Color background = Color(0xFF000000);

  /// 卡片背景色
  static const Color cardBackground = Color(0xFF1C1C1E);

  /// 三级背景色
  static const Color surfaceBackground = Color(0xFF2C2C2E);

  /// 主文字色
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// 副文字色
  static const Color textSecondary = Color(0xFF8E8E93);

  /// 三级文字色
  static const Color textTertiary = Color(0xFF48484A);

  /// 主色调（紫色）
  static const Color primary = Color(0xFF7C3AED);

  /// 渐变起始色
  static const Color gradientStart = Color(0xFF7C3AED);

  /// 渐变结束色
  static const Color gradientEnd = Color(0xFF3B82F6);

  /// 主渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [gradientStart, gradientEnd],
  );

  // ===== 圆角 =====
  /// 小圆角
  static const double radiusSm = 10.0;

  /// 中圆角
  static const double radiusMd = 14.0;

  /// 大圆角
  static const double radiusLg = 20.0;

  /// 超大圆角
  static const double radiusXl = 24.0;

  // ===== 间距 =====
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ===== 暗黑主题 =====
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      backgroundColor: background,
      cardColor: cardBackground,
      dividerColor: surfaceBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: gradientEnd,
        surface: cardBackground,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D0D0D),
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: const TextStyle(
          color: textPrimary,
          fontSize: 14,
        ),
        bodySmall: const TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
        labelLarge: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
