import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';

/// iOS 风格登录页 — Google / Apple / Email
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// 模拟登录：设置标记后返回 true
  static Future<void> _mockLoginAndReturn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_logged_in', true);
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment(-1, -1),
                      end: Alignment(1, 1),
                      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI FaceSwap',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Swap faces with AI in seconds',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                // Continue with Google
                _buildSocialButton(
                  context,
                  icon: _buildGoogleIcon(),
                  label: 'Continue with Google',
                  onPressed: () => _mockLoginAndReturn(context),
                ),
                const SizedBox(height: 12),
                // Continue with Apple
                _buildSocialButton(
                  context,
                  icon: const Icon(Icons.apple, color: Colors.black, size: 22),
                  label: 'Continue with Apple',
                  onPressed: () => _mockLoginAndReturn(context),
                ),
                const SizedBox(height: 12),
                // Sign in with Email
                _buildSocialButton(
                  context,
                  icon: const Icon(Icons.mail_outline, color: Colors.black, size: 20),
                  label: 'Sign in with Email',
                  onPressed: () async {
                    final result = await Navigator.pushNamed(context, '/email-login');
                    if (result == true && context.mounted) {
                      // Email 登录成功，关闭登录页并传递结果
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
                const SizedBox(height: 40),
                const Text(
                  'By continuing you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 简单的彩色 G 图标
  static Widget _buildGoogleIcon() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF4285F4), // Blue
          Color(0xFFEA4335), // Red
          Color(0xFFFBBC05), // Yellow
          Color(0xFF34A853), // Green
        ],
        stops: [0.0, 0.33, 0.66, 1.0],
      ).createShader(bounds),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _buildSocialButton(
    BuildContext context, {
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: MaterialButton(
        onPressed: onPressed,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
