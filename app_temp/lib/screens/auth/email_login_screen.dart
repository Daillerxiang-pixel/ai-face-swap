import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// 邮箱密码登录/注册页
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUp = false; // false=登录, true=注册

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 校验
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_isSignUp) {
      final confirm = _confirmPasswordController.text.trim();
      if (confirm != password) {
        _showError('Passwords do not match');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      // 登录/注册单独拉长超时并允许一次重试，弱网/跨境 DNS 下更易成功
      final authOptions = Options(
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        connectTimeout: const Duration(seconds: 60),
      );

      late final Response response;
      if (_isSignUp) {
        response = await _postAuthWithRetry(
          api,
          '/api/auth/register',
          {'email': email, 'password': password},
          authOptions,
        );
      } else {
        response = await _postAuthWithRetry(
          api,
          '/api/auth/login',
          {'email': email, 'password': password},
          authOptions,
        );
      }

      final data = response.data;
      if (data['success'] == true) {
        final token = data['data']['token'];
        final userId = data['data']['user']['id'].toString();
        AuthService().setToken(token, userId: userId);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_logged_in', true);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) _showError(data['error'] ?? data['message'] ?? 'Authentication failed');
      }
    } on DioException catch (e) {
      if (mounted) {
        _showError(_dioErrorMessage(e));
      }
    } catch (e) {
      if (mounted) _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  /// 登录/注册 POST，失败时在可恢复错误下自动重试 1 次。
  Future<Response<dynamic>> _postAuthWithRetry(
    ApiService api,
    String path,
    Map<String, dynamic> data,
    Options options,
  ) async {
    DioException? last;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await api.dio.post<dynamic>(path, data: data, options: options);
      } on DioException catch (e) {
        last = e;
        if (attempt == 0 && _isTransientAuthFailure(e)) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }
        rethrow;
      }
    }
    throw last!;
  }

  bool _isTransientAuthFailure(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  String _dioErrorMessage(DioException e) {
    final base = AppConfig.apiBaseUrl;
    String hint = ' (API: $base)';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Check network or VPN.$hint';
      case DioExceptionType.connectionError:
        return 'Cannot reach server. Check network or firewall.$hint';
      case DioExceptionType.badResponse:
        break;
      default:
        if (e.response == null) {
          return 'Network error.$hint';
        }
    }
    if (e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map) {
        final m = d['error'] ?? d['message'];
        if (m != null) return m.toString();
      }
    }
    return 'Request failed: ${e.message ?? e.type}$hint';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar with Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, color: AppTheme.primary, size: 28),
                        SizedBox(width: 0),
                        Text('Back', style: TextStyle(color: AppTheme.primary, fontSize: 17)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSignUp ? 'Create Account' : 'Sign In',
                      style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp ? 'Join AI FaceSwap today' : 'Welcome back',
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: context.appColors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: context.appColors.textSecondary),
                        filled: true,
                        fillColor: context.appColors.surfaceBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appColors.surfaceBackground),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: context.appColors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: context.appColors.textSecondary),
                        filled: true,
                        fillColor: context.appColors.surfaceBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appColors.surfaceBackground),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: context.appColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Confirm Password (only for sign up)
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: context.appColors.textPrimary, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: context.appColors.textSecondary),
                          filled: true,
                          fillColor: context.appColors.surfaceBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.appColors.surfaceBackground),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                    // Forgot Password (only for sign in)
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Forgot Password coming soon')),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: AppTheme.primary, fontSize: 14),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: MaterialButton(
                          onPressed: _isLoading ? null : _onSubmit,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isSignUp ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Toggle sign in / sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                          style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
