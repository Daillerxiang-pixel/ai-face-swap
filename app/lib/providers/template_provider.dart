import 'package:flutter/foundation.dart';
import '../models/template.dart';
import '../services/api_service.dart';

/// 模板状态管理
class TemplateProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  /// 推荐模板列表
  List<Template> _templates = [];

  /// 热门模板列表
  List<Template> _hotTemplates = [];

  /// 收藏模板列表
  List<Template> _favorites = [];

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在加载更多
  bool _isLoadingMore = false;

  /// 当前页码
  int _currentPage = 1;

  /// 是否还有更多数据
  bool _hasMore = true;

  /// 错误信息
  String? _error;

  List<Template> get templates => _templates;
  List<Template> get hotTemplates => _hotTemplates;
  List<Template> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// 加载推荐模板
  Future<void> loadTemplates({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getTemplates(
        sort: 'recommend',
        page: _currentPage,
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

      _hasMore = list.length >= 20;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载热门模板
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
    } catch (_) {
      // 热门加载失败不影响主流程
    }
  }

  /// 加载收藏列表
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

  /// 收藏/取消收藏
  Future<void> toggleFavorite(String templateId) async {
    try {
      final res = await _api.toggleFavorite(templateId);
      if (res.success) {
        // 更新本地列表中的收藏状态
        for (final t in _templates) {
          if (t.id == templateId) {
            _templates = _templates.map((item) {
              if (item.id == templateId) {
                return Template(
                  id: item.id,
                  name: item.name,
                  cover: item.cover,
                  preview: item.preview,
                  category: item.category,
                  scene: item.scene,
                  useCount: item.useCount,
                  isFavorite: !(item.isFavorite ?? false),
                  description: item.description,
                  createdAt: item.createdAt,
                );
              }
              return item;
            }).toList();
            break;
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    await loadTemplates();

    _isLoadingMore = false;
    notifyListeners();
  }
}
