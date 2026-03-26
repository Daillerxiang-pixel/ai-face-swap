/// 生成记录数据模型
class Generation {
  /// 安全地将 dynamic 值转为 int
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  /// 将后端 type 字段归一化（兼容中文）
  static String _normalizeType(dynamic value) {
    final str = value?.toString().trim().toLowerCase() ?? '';
    if (str == 'image' || str == '图片') return 'image';
    if (str == 'video' || str == '视频') return 'video';
    return str.isEmpty ? 'image' : str;
  }

  final String id;
  final String templateId;
  final String? templateName;
  final String? templateCover;
  final String? templatePreview;
  final String? sourceFileId;
  final String? resultImage;
  final String status;
  final String? type; // 'image' or 'video'
  final String? provider; // 'akool', 'tencent', etc.
  final String? errorMessage;
  final int progress;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Generation({
    required this.id,
    required this.templateId,
    this.templateName,
    this.templateCover,
    this.templatePreview,
    this.sourceFileId,
    this.resultImage,
    required this.status,
    this.type,
    this.provider,
    this.errorMessage,
    this.progress = 0,
    this.createdAt,
    this.completedAt,
  });

  bool get isProcessing => status == 'pending' || status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isVideo => type == 'video';

  factory Generation.fromJson(Map<String, dynamic> json) {
    // 兼容 created_at (snake_case) 和 createdAt (camelCase)
    final createdAtRaw = json['createdAt']?.toString() ?? json['created_at']?.toString();
    final completedAtRaw = json['completedAt']?.toString() ?? json['completed_at']?.toString();

    // 兼容 "yyyy-MM-dd HH:mm:ss" 格式
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      String normalized = raw.replaceAll(' ', 'T');
      return DateTime.tryParse(normalized);
    }

    return Generation(
      id: json['id']?.toString() ?? json['generationId']?.toString() ?? '',
      templateId: json['templateId']?.toString() ?? json['template_id']?.toString() ?? '',
      templateName: json['templateName']?.toString() ?? json['template_name']?.toString(),
      templateCover: json['templateCover']?.toString() ?? json['template_cover']?.toString(),
      templatePreview: json['templatePreview']?.toString() ?? json['template_preview']?.toString(),
      sourceFileId: json['sourceFileId']?.toString() ?? json['source_file_id']?.toString(),
      resultImage: json['resultImage']?.toString() ?? json['resultUrl']?.toString() ?? json['result_image']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      type: _normalizeType(json['type']),
      provider: json['provider']?.toString(),
      errorMessage: json['errorMessage']?.toString() ?? json['errorMsg']?.toString() ?? json['error']?.toString() ?? json['error_message']?.toString(),
      progress: (json['progress'] is int) ? json['progress'] as int : int.tryParse(json['progress']?.toString() ?? '0') ?? 0,
      createdAt: parseDate(createdAtRaw),
      completedAt: parseDate(completedAtRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'templateName': templateName,
      'templateCover': templateCover,
      'templatePreview': templatePreview,
      'sourceFileId': sourceFileId,
      'resultImage': resultImage,
      'status': status,
      'type': type,
      'provider': provider,
      'errorMessage': errorMessage,
      'progress': progress,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
