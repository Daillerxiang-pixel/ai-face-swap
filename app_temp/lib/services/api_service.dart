import 'dart:io';

import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../config/app_config.dart';
import '../models/recharge_plan.dart';

/// API 统一响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final int? page;
  final int? limit;
  final String? message;
  final String? errorCode; // 错误码，如 QUOTA_EXCEEDED

  ApiResponse({
    required this.success,
    this.data,
    this.page,
    this.limit,
    this.message,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJson,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: fromJson != null ? fromJson(json['data']) : json['data'] as T?,
      page: json['page'] is int
          ? json['page']
          : int.tryParse(json['page']?.toString() ?? ''),
      limit: json['limit'] is int
          ? json['limit']
          : int.tryParse(json['limit']?.toString() ?? ''),
      message: json['message'] ?? json['error'],
      errorCode: json['errorCode'],
    );
  }
}

/// HTTP API 封装服务
class ApiService {
  late final Dio _dio;

  /// 暴露 Dio 实例供登录等直接 HTTP 调用使用
  Dio get dio => _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.apiConnectTimeout,
      receiveTimeout: AppConfig.apiReceiveTimeout,
      sendTimeout: AppConfig.apiSendTimeout,
      // 默认仅 2xx 为「成功」，401/403 会抛 DioException，UI 只能显示 Network error。
      // 与后端约定：4xx 返回 JSON { success, error }，须解析后提示「重新登录」等。
      validateStatus: (status) => status != null && status < 500,
    ));

    // 请求拦截器 — 自动附加 token（登录/注册不得带旧 Token，否则部分环境下会 401 导致无法登录）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final p = options.uri.path;
        final isAnonymousAuth = p.contains('/api/auth/login') ||
            p.contains('/api/auth/register');
        if (isAnonymousAuth) {
          options.headers.remove('Authorization');
        } else {
          final token = AuthService().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ));

    // 401 — 清理本地 Token（排除「密码错误」的登录 401）
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (error is DioException && error.response?.statusCode == 401) {
          final p = error.requestOptions.uri.path;
          final isLoginFailure = p.contains('/api/auth/login') ||
              p.contains('/api/auth/register');
          if (!isLoginFailure) {
            AuthService().clearToken();
          }
        }
        return handler.next(error);
      },
    ));

    // 重试拦截器 — 写操作失败时自动重试 1 次
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        final method = error.requestOptions.method;
        // 仅对写操作（POST/PUT/DELETE）且非 4xx 业务错误时重试
        if (_isWriteMethod(method) && error.response?.statusCode != null && error.response!.statusCode! >= 500) {
          try {
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));

    // 日志拦截器
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
    ));
  }

  /// 获取模板列表
  Future<ApiResponse> getTemplates({
    String? sort,
    String? search,
    int limit = AppConfig.pageSize,
    int page = 1,
    String? scene,
    String? type,
  }) async {
    // 将英文 type 映射为后端中文值
    String? backendType;
    if (type == 'image') backendType = '图片';
    else if (type == 'video') backendType = '视频';

    final response = await _dio.get('/api/templates', queryParameters: {
      if (sort != null) 'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': limit,
      'page': page,
      if (scene != null) 'scene': scene,
      if (backendType != null) 'type': backendType,
    });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 全库按类型的模板数量（图片 / 视频），用于首页等展示
  Future<ApiResponse<Map<String, dynamic>>> getTemplateTypeCounts() async {
    final response = await _dio.get('/api/templates/meta/counts');
    final map = response.data as Map<String, dynamic>;
    return ApiResponse.fromJson(map, (data) {
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    });
  }

  /// 获取场景列表
  Future<ApiResponse> getScenes({String? type}) async {
    // 将英文 type 映射为后端中文值
    String? backendType;
    if (type == 'image') backendType = '图片';
    else if (type == 'video') backendType = '视频';

    final response = await _dio.get('/api/templates/meta/scenes',
        queryParameters: {
          if (backendType != null) 'type': backendType,
        });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 获取模板详情
  Future<ApiResponse> getTemplateDetail(String id) async {
    final response = await _dio.get('/api/templates/$id');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 上传图片
  /// multipart 时须显式带上 Authorization，否则部分环境下拦截器不会合并到最终请求。
  Future<ApiResponse> uploadImage(String filePath) async {
    final sep = filePath.replaceAll('\\', '/').lastIndexOf('/');
    final filename =
        sep < 0 ? filePath : filePath.substring(sep + 1);
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          filePath,
          filename: filename.isEmpty ? 'photo.jpg' : filename,
        ),
      });
      final token = AuthService().token;
      final response = await _dio.post(
        '/api/upload/image',
        data: formData,
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data,
      );
    } on DioException catch (e) {
      return _responseFromDioException(e);
    }
  }

  /// 创建生成任务
  Future<ApiResponse> createGeneration({
    required String templateId,
    required String sourceFileId,
  }) async {
    final response = await _dio.post('/api/generate', data: {
      'templateId': templateId,
      'sourceFileId': sourceFileId,
    });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 查询生成状态
  Future<ApiResponse> getGenerationStatus(String id) async {
    final response = await _dio.get('/api/generate/$id/status');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 获取用户信息
  Future<ApiResponse> getUserProfile() async {
    final response = await _dio.get('/api/user/profile');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 获取历史记录
  Future<ApiResponse> getUserHistory({
    int page = 1,
    int limit = AppConfig.pageSize,
  }) async {
    final response = await _dio.get('/api/user/history', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 获取收藏列表
  Future<ApiResponse> getFavorites({
    int page = 1,
    int limit = AppConfig.pageSize,
  }) async {
    final response = await _dio.get('/api/user/favorites', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 收藏/取消收藏模板 (POST toggle)
  Future<ApiResponse> toggleFavorite(String templateId) async {
    // Check current state first
    final checkRes = await _dio.get('/api/user/favorite/$templateId');
    final isFav = checkRes.data['data']?['favorited'] == true;

    if (isFav) {
      final response = await _dio.delete('/api/favorites/$templateId');
      return ApiResponse.fromJson(response.data, (data) => data);
    } else {
      final response = await _dio.post('/api/favorites', data: {'template_id': templateId});
      return ApiResponse.fromJson(response.data, (data) => data);
    }
  }

  /// 收藏模板 (POST /api/favorites)
  Future<ApiResponse> addFavorite(String templateId) async {
    final response = await _dio.post('/api/favorites', data: {'template_id': templateId});
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 取消收藏 (DELETE /api/favorites/:templateId)
  Future<ApiResponse> removeFavorite(String templateId) async {
    final response = await _dio.delete('/api/favorites/$templateId');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 更新用户设置
  Future<ApiResponse> updateUserSettings({
    String? nickname,
    String? avatar,
    bool? autoSave,
    String? theme,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;
    if (autoSave != null) body['auto_save'] = autoSave;
    if (theme != null) body['theme'] = theme;
    try {
      final response = await _dio.put('/api/user/settings', data: body);
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data,
      );
    } on DioException catch (e) {
      return _responseFromDioException(e);
    }
  }

  /// 验证 Apple 订阅 receipt
  Future<ApiResponse> verifySubscription({
    required String productId,
    required String receiptData,
    required String transactionId,
  }) async {
    final response = await _dio.post('/api/subscription/verify', data: {
      'productId': productId,
      'receiptData': receiptData,
      'transactionId': transactionId,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 获取当前订阅状态
  Future<ApiResponse> getSubscriptionStatus() async {
    final response = await _dio.get('/api/subscription/status');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 充值套餐列表（公开接口，无需登录；与后台「套餐管理」同源）
  Future<ApiResponse<List<RechargePlan>>> getRechargePlans() async {
    try {
      final response = await _dio.get('/api/plans');
      final map = response.data as Map<String, dynamic>;
      return ApiResponse.fromJson(map, (data) {
        if (data is! List) return <RechargePlan>[];
        return data
            .map((e) => RechargePlan.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });
    } on DioException catch (e) {
      final r = _responseFromDioException(e);
      return ApiResponse<List<RechargePlan>>(
        success: r.success,
        message: r.message,
        data: null,
      );
    }
  }

  bool _isWriteMethod(String method) {
    return method == 'POST' || method == 'PUT' || method == 'DELETE' || method == 'PATCH';
  }

  /// Dio 在 4xx/5xx 时会抛异常，解析为 [ApiResponse] 供上层展示服务端文案（避免误判为「网络失败」）。
  ApiResponse<dynamic> _responseFromDioException(DioException e) {
    final raw = e.response?.data;
    if (raw is Map<String, dynamic>) {
      return ApiResponse.fromJson(raw, (data) => data);
    }
    if (raw is Map) {
      return ApiResponse.fromJson(
        Map<String, dynamic>.from(raw),
        (data) => data,
      );
    }
    return ApiResponse<dynamic>(
      success: false,
      message: e.message ?? 'Network error',
    );
  }
}
