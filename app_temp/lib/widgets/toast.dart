import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/theme.dart';

/// Toast 通知工具
class AppToast {
  AppToast._();

  static void success(String message) {
    _show(message, bg: const Color(0xFF34C759));
  }

  static void error(String message) {
    _show(message, bg: const Color(0xFFFF3B30));
  }

  static void warning(String message) {
    _show(message, bg: const Color(0xFFFF9500));
  }

  static void info(String message) {
    _show(message);
  }

  static void _show(String message, {Color? bg}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: bg ?? AppTheme.surfaceBackground,
      textColor: AppTheme.textPrimary,
      fontSize: 14,
    );
  }
}
