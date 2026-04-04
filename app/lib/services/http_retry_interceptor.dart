import 'package:dio/dio.dart';

/// 对连接/发送/读超时与连接错误做有限次重试（适合跨境、VPN、弱网）。
class HttpRetryInterceptor extends Interceptor {
  HttpRetryInterceptor(this._dio, {required this.maxRetries});

  final Dio _dio;
  final int maxRetries;

  static bool _retryable(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final used = (err.requestOptions.extra['retries'] as int?) ?? 0;
    if (!_retryable(err) || used >= maxRetries) {
      return handler.next(err);
    }
    err.requestOptions.extra['retries'] = used + 1;
    await Future<void>.delayed(Duration(milliseconds: 400 * (1 << used)));
    try {
      final res = await _dio.fetch(err.requestOptions);
      return handler.resolve(res);
    } catch (e) {
      if (e is DioException) {
        return onError(e, handler);
      }
      return handler.next(err);
    }
  }
}
