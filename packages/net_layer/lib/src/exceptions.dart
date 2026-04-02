/// 统一异常定义
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 网络连接异常
class NetworkException extends ApiException {
  const NetworkException({super.message = 'Network error'});
}

/// 超时异常
class TimeoutException extends ApiException {
  const TimeoutException({super.message = 'Request timeout'});
}

/// 未授权异常（401）
class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Unauthorized', super.statusCode = 401});
}

/// 配额超限异常
class QuotaExceededException extends ApiException {
  const QuotaExceededException({super.message = 'Quota exceeded', super.errorCode = 'QUOTA_EXCEEDED'});
}
