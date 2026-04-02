import 'dart:io';

import 'package:dio/dio.dart';

import 'api_response.dart';
import 'exceptions.dart';

/// Token 获取回调 —— 由调用方（auth_suite）注入
typedef TokenGetter = String? Function();

/// HTTP API 客户端封装
class ApiClient {
  late final Dio _dio;

  /// 暴露 Dio 实例（供特殊场景直接使用）
  Dio get dio => _dio;

  /// 构造 API 客户端
  ///
  /// [baseUrl] API 基础地址
  /// [tokenGetter] 可选的 Token 获取函数，自动注入 Authorization header
  /// [connectTimeout] 连接超时（默认 15 秒）
  /// [receiveTimeout] 响应超时（默认 30 秒）
  ApiClient({
    required String baseUrl,
    TokenGetter? tokenGetter,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    ));

    // Token 注入拦截器
    if (tokenGetter != null) {
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokenGetter();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ));
    }

    // 重试拦截器 —— 写操作 5xx 自动重试 1 次
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        final method = error.requestOptions.method;
        final status = error.response?.statusCode;
        if (_isWriteMethod(method) && status != null && status >= 500) {
          try {
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (_) {
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

  // ─── 便捷方法 ───────────────────────────────────────

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.post(path, data: data, queryParameters: queryParameters);
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  Future<ApiResponse> put(
    String path, {
    dynamic data,
  }) async {
    final response = await _dio.put(path, data: data);
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  Future<ApiResponse> delete(String path) async {
    final response = await _dio.delete(path);
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  Future<ApiResponse> upload(String path, String filePath, {String field = 'file'}) async {
    final formData = FormData.fromMap({
      field: await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(path, data: formData);
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  // ─── 内部工具 ───────────────────────────────────────

  bool _isWriteMethod(String method) {
    return method == 'POST' || method == 'PUT' || method == 'DELETE' || method == 'PATCH';
  }
}
