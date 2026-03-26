import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/theme.dart';

/// Toast 通知工具
class Toast {
  Toast._();

  /// 显示成功提示
  static void success(String message) {
    _show(message, backgroundColor: const Color(0xFF34C759));
  }

  /// 显示错误提示
  static void error(String message) {
    _show(message, backgroundColor: const Color(0xFFFF3B30));
  }

  /// 显示警告提示
  static void warning(String message) {
    _show(message, backgroundColor: const Color(0xFFFF9500));
  }

  /// 显示普通提示
  static void info(String message) {
    _show(message);
  }

  static void _show(
    String message, {
    Color? backgroundColor,
    Color textColor = AppTheme.textPrimary,
    ToastGravity gravity = ToastGravity.CENTER,
    int timeInSecForIosWeb = 1,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: timeInSecForIosWeb,
      backgroundColor: backgroundColor ?? AppTheme.surfaceBackground,
      textColor: textColor,
      fontSize: 14,
    );
  }
}
