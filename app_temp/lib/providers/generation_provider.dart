import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/generation.dart';
import '../services/api_service.dart';

/// 生成任务状态管理
class GenerationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  /// 历史记录列表
  List<Generation> _history = [];

  /// 当前正在处理的任务
  Generation? _currentGeneration;

  /// 是否正在加载
  bool _isLoading = false;

  /// 错误信息
  String? _error;

  /// 轮询定时器
  Timer? _pollTimer;

  /// 轮询次数
  int _pollCount = 0;

  List<Generation> get history => _history;
  Generation? get currentGeneration => _currentGeneration;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProcessing => _pollTimer != null;

  /// 加载历史记录
  Future<void> loadHistory({bool refresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getUserHistory().timeout(const Duration(seconds: 5));
      if (res.success && res.data != null) {
        _history = (res.data as List?)
                ?.map((e) =>
                    Generation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建生成任务（不再在此处轮询，由 UI 层控制）
  /// 返回创建结果
  Future<Map<String, dynamic>?> createGeneration({
    required String templateId,
    required String sourceFileId,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final res = await _api.createGeneration(
        templateId: templateId,
        sourceFileId: sourceFileId,
      );

      if (res.success && res.data != null) {
        return res.data as Map<String, dynamic>;
      } else {
        _error = res.message ?? '创建任务失败';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 查询生成状态（单次）
  Future<Generation?> checkStatus(String generationId) async {
    try {
      final res = await _api.getGenerationStatus(generationId);
      if (res.success && res.data != null) {
        return Generation.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// 开始轮询生成状态（兼容旧接口）
  void startPolling(String generationId) {
    stopPolling();
    _pollCount = 0;

    _pollTimer = Timer.periodic(
      const Duration(milliseconds: AppConfig.pollInterval),
      (_) async {
        _pollCount++;
        if (_pollCount * AppConfig.pollInterval ~/ 1000 >
            AppConfig.maxWaitSeconds) {
          stopPolling();
          _error = '生成超时';
          notifyListeners();
          return;
        }

        final gen = await checkStatus(generationId);
        if (gen == null) return;

        _currentGeneration = gen;

        if (gen.isCompleted || gen.isFailed) {
          stopPolling();
          // 刷新历史
          loadHistory();
        }

        notifyListeners();
      },
    );

    notifyListeners();
  }

  /// 停止轮询
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
