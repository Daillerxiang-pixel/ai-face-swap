/// 统一 API 响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final int? page;
  final int? limit;
  final String? message;
  final String? errorCode;

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

  @override
  String toString() =>
      'ApiResponse(success: $success, data: $data, message: $message, errorCode: $errorCode)';
}
