import 'package:dio/dio.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

/// Apple Sign In service
class AppleSignInService {
  AppleSignInService._();

  static final AppleSignInService _instance = AppleSignInService._();
  factory AppleSignInService() => _instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.apiConnectTimeout,
    receiveTimeout: AppConfig.apiReceiveTimeout,
    sendTimeout: AppConfig.apiSendTimeout,
    headers: {'X-Client-App': AppConfig.clientApp},
  ));

  /// Perform Apple Sign In flow
  Future<bool> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw Exception('Apple Sign In failed: no identityToken');
      }

      final response = await _dio.post('/api/auth/apple', data: {
        'identityToken': identityToken,
        'authorizationCode': credential.authorizationCode,
        'client_app': AppConfig.clientApp,
        if (credential.givenName != null) 'firstName': credential.givenName,
        if (credential.familyName != null) 'lastName': credential.familyName,
        if (credential.email != null) 'email': credential.email,
      });

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final token = data['data']['token'] as String?;
        final userMap = data['data']['user'];
        final userId = userMap is Map
            ? userMap['id']?.toString()
            : data['data']['userId']?.toString();

        if (token != null && token.isNotEmpty) {
          AuthService().setToken(token, userId: userId);
          return true;
        }
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }
}
