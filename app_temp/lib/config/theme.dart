import 'package:flutter/material.dart';

/// 自定义主题扩展 - 存储应用特有颜色
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color cardBackground;
  final Color surfaceBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const AppColors({
    required this.background,
    required this.cardBackground,
    required this.surfaceBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? cardBackground,
    Color? surfaceBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) {
    return AppColors(
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      surfaceBackground: Color.lerp(surfaceBackground, other.surfaceBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}

/// 应用主题配置（iOS 风格）
class AppTheme {
  AppTheme._();

  // ===== 暗色主题颜色（默认）=====
  static const Color background = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF1C1C1E);
  static const Color surfaceBackground = Color(0xFF2C2C2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);
  static const Color text2 = textSecondary;
  static const Color text3 = textTertiary;
  static const Color surface = surfaceBackground;
  static const Color card = cardBackground;

  // ===== 亮色主题颜色 =====
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightSurfaceBackground = Color(0xFFE5E5EA);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightTextTertiary = Color(0xFFC7C7CC);

  // ===== 通用颜色 =====
  static const Color primary = Color(0xFF7C3AED);
  static const Color gradientStart = Color(0xFF7C3AED);
  static const Color gradientEnd = Color(0xFF3B82F6);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [gradientStart, gradientEnd],
  );

  // ===== 圆角 =====
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;

  // ===== 间距 =====
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ===== 暗色自定义颜色 =====
  static const appColorsDark = AppColors(
    background: background,
    cardBackground: cardBackground,
    surfaceBackground: surfaceBackground,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
  );

  // ===== 亮色自定义颜色 =====
  static const appColorsLight = AppColors(
    background: lightBackground,
    cardBackground: lightCardBackground,
    surfaceBackground: lightSurfaceBackground,
    textPrimary: lightTextPrimary,
    textSecondary: lightTextSecondary,
    textTertiary: lightTextTertiary,
  );

  // ===== 暗黑主题 =====
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      dividerColor: surfaceBackground,
      extensions: <ThemeExtension<dynamic>>[appColorsDark],
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: gradientEnd,
        surface: cardBackground,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: textTertiary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
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

  // ===== 亮色主题 =====
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCardBackground,
      dividerColor: lightSurfaceBackground,
      extensions: <ThemeExtension<dynamic>>[appColorsLight],
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: gradientEnd,
        surface: lightCardBackground,
        onPrimary: lightTextPrimary,
        onSecondary: lightTextPrimary,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        outline: lightTextTertiary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: primary,
        unselectedItemColor: lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      cardTheme: CardTheme(
        color: lightCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          color: lightTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: const TextStyle(
          color: lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: const TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          color: lightTextPrimary,
          fontSize: 16,
        ),
        bodyMedium: const TextStyle(
          color: lightTextPrimary,
          fontSize: 14,
        ),
        bodySmall: const TextStyle(
          color: lightTextSecondary,
          fontSize: 12,
        ),
        labelLarge: const TextStyle(
          color: lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// BuildContext 扩展 - 通过 ThemeExtension 获取自定义颜色（Flutter 原生主题系统）
extension ThemeColors on BuildContext {
  /// 获取自定义颜色（跟随主题自动切换，Flutter 原生机制高效更新）
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
