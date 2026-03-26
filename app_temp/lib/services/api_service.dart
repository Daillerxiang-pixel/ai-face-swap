import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// API 统一响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final int? page;
  final int? limit;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.page,
    this.limit,
    this.message,
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
      message: json['message'],
    );
  }
}

/// HTTP API 封装服务
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        // 不设置 Content-Type，让 Dio 根据请求类型自动设置
        // multipart/form-data 请求如果被设为 application/json 会导致上传失败
        'X-User-Id': AppConfig.mockUserId,
      },
    ));

    // 请求拦截器
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
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
    final response = await _dio.get('/api/templates', queryParameters: {
      if (sort != null) 'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': limit,
      'page': page,
      if (scene != null) 'scene': scene,
      if (type != null) 'type': type,
    });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 获取场景列表
  Future<ApiResponse> getScenes({String? type}) async {
    final response = await _dio.get('/api/templates/meta/scenes',
        queryParameters: {
          if (type != null) 'type': type,
        });
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 获取模板详情
  Future<ApiResponse> getTemplateDetail(String id) async {
    final response = await _dio.get('/api/templates/$id');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// 上传图片
  Future<ApiResponse> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/api/upload/image', data: formData);
    return ApiResponse.fromJson(response.data, (data) => data);
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

  /// 收藏/取消收藏模板
  Future<ApiResponse> toggleFavorite(String templateId) async {
    final response = await _dio.post('/api/templates/$templateId/favorite');
    return ApiResponse.fromJson(response.data, (data) => data);
  }
}
