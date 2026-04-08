import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/template.dart';
import '../services/api_service.dart';

/// 模板状态管理
class TemplateProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Template> _templates = [];
  List<Template> _hotTemplates = [];
  List<Template> _favorites = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _error;

  List<Template> get templates => _templates;
  List<Template> get hotTemplates => _hotTemplates;
  List<Template> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// Load first page or replace list ([refresh] = true).
  Future<void> loadTemplates({
    bool refresh = false,
    String? scene,
    String? search,
    String? type,
  }) async {
    if (refresh) {
      if (_isLoading) return;
    } else {
      if (_isLoadingMore || !_hasMore) return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final page = refresh ? 1 : _currentPage;
      final res = await _api.getTemplates(
        sort: 'recommend',
        page: page,
        limit: AppConfig.pageSize,
        scene: scene,
        search: search,
        type: type,
      );
      final list = (res.data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      if (refresh) {
        _templates = list;
      } else {
        _templates.addAll(list);
      }

      _hasMore = list.length >= AppConfig.pageSize;
      _currentPage = page + 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadHotTemplates() async {
    try {
      final res = await _api.getTemplates(
        sort: 'hot',
        limit: 10,
      );
      _hotTemplates = (res.data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadFavorites() async {
    try {
      final res = await _api.getFavorites();
      _favorites = (res.data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String templateId) async {
    try {
      final res = await _api.toggleFavorite(templateId);
      if (res.success) {
        final data = res.data;
        final isFav = data is Map && data['favorited'] == true;

        _templates = _templates.map((item) {
          if (item.id == templateId) {
            return item.copyWith(isFavorite: isFav);
          }
          return item;
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadMore({
    String? scene,
    String? search,
    String? type,
  }) async {
    await loadTemplates(
      refresh: false,
      scene: scene,
      search: search,
      type: type,
    );
  }
}
