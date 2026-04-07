import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../screens/auth/login_screen.dart';
import '../services/auth_service.dart';

/// 换脸 / 生成前需要登录。未登录时弹窗说明，确认后进入登录页。
/// 返回 `true` 表示已登录（原本就登录或登录成功）。
Future<bool> ensureLoggedInForCreate(BuildContext context) async {
  if (AuthService().isLoggedIn) return true;

  final shouldLogin = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.appColors.cardBackground,
      title: Text(
        '需要登录',
        style: TextStyle(
          color: ctx.appColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        '使用模板换脸前请先登录账号。',
        style: TextStyle(color: ctx.appColors.textSecondary, fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('取消', style: TextStyle(color: ctx.appColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('去登录', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  if (shouldLogin != true || !context.mounted) return false;

  final loggedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );

  return loggedIn == true && AuthService().isLoggedIn;
}

bool isAuthErrorMessage(String? message) {
  if (message == null || message.isEmpty) return false;
  final m = message.toLowerCase();
  return m.contains('not authenticated') ||
      m.contains('invalid or expired token') ||
      m.contains('未登录');
}
