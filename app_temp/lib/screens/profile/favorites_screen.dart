import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../providers/template_provider.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/empty_state_widget.dart';
import '../create/upload_photo_screen.dart';

/// 收藏页面 — 从 API 加载真实收藏列表
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _api = ApiService();
  int _currentTab = 0; // 0: All, 1: Photo, 2: Video
  List<Template> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.getFavorites();
      if (res.success && res.data != null) {
        final list = (res.data as List).map((e) {
          final map = e as Map<String, dynamic>;
          return Template.fromJson({
            ...map,
            'isFavorite': true,
          });
        }).toList();
        if (mounted) setState(() => _favorites = list);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load favorites');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(Template tpl) async {
    try {
      await _api.removeFavorite(tpl.id.toString());
      setState(() => _favorites.remove(tpl));
      // Also sync with TemplateProvider
      if (mounted) {
        context.read<TemplateProvider>().loadFavorites();
      }
    } catch (_) {}
  }

  List<Template> get _filteredFavorites {
    if (_currentTab == 0) return _favorites;
    final type = _currentTab == 1 ? 'image' : 'video';
    return _favorites.where((t) => t.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredFavorites;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: _buildBackButton(),
        title: const Text('Favorites'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Type toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: ['All', 'Photo', 'Video'].asMap().entries.map((e) {
                  final isActive = _currentTab == e.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = e.key),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primary : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: isActive ? Colors.white : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          EmptyStateWidget(
                            icon: Icons.wifi_off_outlined,
                            title: 'Failed to load',
                            subtitle: _error,
                            actionText: 'Retry',
                            onAction: _loadFavorites,
                          ),
                        ],
                      )
                    : items.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: AppTheme.primary,
                            backgroundColor: AppTheme.cardBackground,
                            onRefresh: _loadFavorites,
                            child: _buildGrid(items),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left, color: AppTheme.primary, size: 28),
          SizedBox(width: 0),
          Text('Back', style: TextStyle(color: AppTheme.primary, fontSize: 17)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 56, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            const Text('No Favorites Yet', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Browse templates and tap the heart icon to save your favorites',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SelectTemplateScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 0,
              ),
              child: const Text('Browse Templates', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Template> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final tpl = items[index];
        final thumbUrl = ImageUtils.imgUrl(tpl.displayUrl);
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UploadPhotoScreen(template: tpl),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Thumbnail
                if (thumbUrl.isNotEmpty)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: thumbUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.surfaceBackground),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceBackground),
                    ),
                  ),
                // Heart button (tap to unfavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeFavorite(tpl),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                    ),
                  ),
                ),
                // Template name
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      tpl.name,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
