import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../screens/auth/login_screen.dart';
import '../services/auth_service.dart';

/// Require login before face swap / generation. Shows a dialog; opens login on confirm.
/// Returns `true` if already logged in or login succeeded.
Future<bool> ensureLoggedInForCreate(BuildContext context) async {
  if (AuthService().isLoggedIn) return true;

  final shouldLogin = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.appColors.cardBackground,
      title: Text(
        'Sign in required',
        style: TextStyle(
          color: ctx.appColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        'Please sign in to use templates and create swaps.',
        style: TextStyle(color: ctx.appColors.textSecondary, fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: TextStyle(color: ctx.appColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign in', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
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
      m.contains('unauthorized') ||
      m.contains('未登录');
}
