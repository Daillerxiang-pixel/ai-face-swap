import 'package:flutter/foundation.dart';
import '../models/generation.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'dart:async';

/// 生成记录状态管理
class GenerationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  /// 历史记录列表
  List<Generation> _history = [];

  /// 当前生成任务
  Generation? _currentGeneration;

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在上传/生成
  bool _isProcessing = false;

  /// 轮询定时器
  Timer? _pollTimer;

  List<Generation> get history => _history;
  Generation? get currentGeneration => _currentGeneration;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;

  /// 加载历史记录
  Future<void> loadHistory({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getUserHistory();
      _history = (res.data as List?)
              ?.map((e) => Generation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (_) {
      // 加载失败
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建生成任务
  Future<bool> createGeneration({
    required String templateId,
    required String sourceFileId,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final res = await _api.createGeneration(
        templateId: templateId,
        sourceFileId: sourceFileId,
      );
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _currentGeneration = Generation.fromJson(data);
        notifyListeners();

        // 开始轮询状态
        _startPolling(_currentGeneration!.id);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 开始轮询生成状态
  void _startPolling(String generationId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: AppConfig.pollInterval),
      (_) => _checkStatus(generationId),
    );
  }

  /// 检查生成状态
  Future<void> _checkStatus(String generationId) async {
    try {
      final res = await _api.getGenerationStatus(generationId);
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _currentGeneration = Generation.fromJson(data);
        notifyListeners();

        // 如果已完成或失败，停止轮询
        if (_currentGeneration!.isCompleted ||
            _currentGeneration!.isFailed) {
          _pollTimer?.cancel();
          _pollTimer = null;
          // 刷新历史记录
          loadHistory();
        }
      }
    } catch (_) {
      // 轮询失败不中断
    }
  }

  /// 停止轮询
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
