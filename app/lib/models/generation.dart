/// 生成记录数据模型
class Generation {
  final String id;
  final String templateId;
  final String? templateName;
  final String? templateCover;
  final String? sourceFileId;
  final String? resultImage;
  final String status; // pending, processing, completed, failed
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Generation({
    required this.id,
    required this.templateId,
    this.templateName,
    this.templateCover,
    this.sourceFileId,
    this.resultImage,
    required this.status,
    this.errorMessage,
    this.createdAt,
    this.completedAt,
  });

  /// 是否正在处理中
  bool get isProcessing => status == 'pending' || status == 'processing';

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  /// 是否失败
  bool get isFailed => status == 'failed';

  factory Generation.fromJson(Map<String, dynamic> json) {
    return Generation(
      id: json['id']?.toString() ?? '',
      templateId: json['templateId']?.toString() ?? '',
      templateName: json['templateName'],
      templateCover: json['templateCover'],
      sourceFileId: json['sourceFileId'],
      resultImage: json['resultImage'],
      status: json['status'] ?? 'pending',
      errorMessage: json['errorMessage'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'templateName': templateName,
      'templateCover': templateCover,
      'sourceFileId': sourceFileId,
      'resultImage': resultImage,
      'status': status,
      'errorMessage': errorMessage,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
