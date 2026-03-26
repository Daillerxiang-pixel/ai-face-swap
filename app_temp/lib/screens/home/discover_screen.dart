import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../detail/template_detail_screen.dart';

/// 发现页面 — 搜索 + 分段选择器 + 列表展示
/// 参考 index-v4.html discoverPage
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  /// 当前显示的模板列表
  List<Template> _templates = [];

  /// 当前选中的分段索引: 0推荐 1热门 2最新 3VIP
  int _selectedSegIndex = 0;

  /// 是否正在加载
  bool _isLoading = true;

  /// 是否正在下拉刷新
  bool _isRefreshing = false;

  /// 搜索关键词
  String _searchQuery = '';

  /// 防抖定时器
  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTemplates();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// 加载模板（按分段筛选 + 搜索）
  Future<void> _loadTemplates({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      String? sort;
      String? type;

      switch (_selectedSegIndex) {
        case 0: // 推荐
          sort = null;
          break;
        case 1: // 热门
          sort = 'usage';
          break;
        case 2: // 最新
          sort = 'new';
          break;
        case 3: // VIP
          type = 'vip';
          break;
      }

      final res = await _api.getTemplates(
        sort: sort,
        type: type,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 100,
      );

      final list = (res.data as List?)
              ?.map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      setState(() {
        _templates = list;
      });
    } catch (_) {
      if (!isRefresh) {
        setState(() {
          _templates = [];
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// 搜索内容变化
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query == _searchQuery) return;
    _searchQuery = query;

    // 简单防抖：300ms 内不重复触发
    final now = DateTime.now();
    if (_lastSearchTime != null &&
        now.difference(_lastSearchTime!).inMilliseconds < 300) {
      return;
    }
    _lastSearchTime = now;

    // 防抖后触发搜索（用 Future.delayed 确保最后一次输入生效）
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final currentQuery = _searchController.text.trim().toLowerCase();
      if (currentQuery == _searchQuery) {
        _loadTemplates();
      }
    });
  }

  /// 分段选择器点击
  void _onSegChanged(int index) {
    if (index == _selectedSegIndex) return;
    setState(() => _selectedSegIndex = index);
    _loadTemplates();
  }

  /// 格式化使用次数
  String _formatCount(int? count) {
    if (count == null || count == 0) return '0';
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}W';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background,
                    AppTheme.background.withOpacity(0.85),
                  ],
                ),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '发现',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 搜索栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: '搜索模板、风格、场景...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _loadTemplates(),
                ),
              ),
            ),

            // 分段选择器
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildSegItem('推荐', 0),
                    _buildSegItem('热门', 1),
                    _buildSegItem('最新', 2),
                    _buildSegItem('VIP', 3),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // 列表内容（支持下拉刷新）
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: AppTheme.cardBackground,
                onRefresh: () => _loadTemplates(isRefresh: true),
                child: _isLoading
                    ? const LoadingWidget(message: '加载中...')
                    : _templates.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              EmptyStateWidget(
                                icon: Icons.search_off_outlined,
                                title: '暂无结果',
                                subtitle: '换个关键词试试',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: _templates.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 0.5,
                              color:
                                  AppTheme.textTertiary.withOpacity(0.35),
                              indent: 70,
                            ),
                            itemBuilder: (context, index) {
                              final template = _templates[index];
                              return _buildDiscoverItem(template);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分段选择器单项
  Widget _buildSegItem(String label, int index) {
    final isSelected = _selectedSegIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onSegChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color:
                isSelected ? AppTheme.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建发现列表项
  Widget _buildDiscoverItem(Template template) {
    final thumbUrl = ImageUtils.imgUrl(template.displayUrl);

    return InkWell(
      onTap: () => _navigateToDetail(context, template),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // 缩略图 56x56
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: thumbUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.surfaceBackground,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppTheme.textTertiary,
                            size: 24,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.surfaceBackground,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppTheme.textTertiary,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.surfaceBackground,
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppTheme.primary.withOpacity(0.5),
                          size: 24,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // 评分 + 使用次数
                  Row(
                    children: [
                      const Text(
                        '⭐',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        ' ${(template.rating ?? 0).toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatCount(template.useCount)} 次使用',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 右箭头
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// 跳转模板详情
  void _navigateToDetail(BuildContext context, Template template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateDetailScreen(template: template),
      ),
    );
  }
}
