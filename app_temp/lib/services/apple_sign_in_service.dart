import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

/// Apple Sign In 接入服务
class AppleSignInService {
  AppleSignInService._();

  static final AppleSignInService _instance = AppleSignInService._();
  factory AppleSignInService() => _instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// 执行 Apple Sign In 流程
  ///
  /// 1. 调用系统 Apple 登录弹窗
  /// 2. 获取 identityToken + authorizationCode
  /// 3. 发送到后端 /api/auth/apple 换取 JWT
  /// 4. 存储 JWT 到 AuthService
  ///
  /// 返回 true 表示登录成功
  Future<bool> signIn() async {
    try {
      // Step 1: 调用 Apple Sign In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Step 2: 检查 identityToken
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw Exception('Apple Sign In failed: no identityToken');
      }

      final authorizationCode = credential.authorizationCode;

      // Step 3: 发送到后端换取 JWT
      final response = await _dio.post('/api/auth/apple', data: {
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        if (credential.givenName != null) 'firstName': credential.givenName,
        if (credential.familyName != null) 'lastName': credential.familyName,
        if (credential.email != null) 'email': credential.email,
      });

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final token = data['data']['token'] as String?;
        final userId = data['data']['userId']?.toString();

        if (token != null && token.isNotEmpty) {
          // Step 4: 存储 JWT
          AuthService().setToken(token, userId: userId);
          return true;
        }
      }

      return false;
    } on SignInWithAppleException catch (e) {
      // 用户取消或其他 Apple 错误
      throw Exception('Apple Sign In error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// iOS 检查 credential 状态（用于恢复登录）
  Future<CredentialState> checkCredentialState(String userIdentifier) async {
    return await SignInWithApple.getCredentialState(userIdentifier);
  }
}
