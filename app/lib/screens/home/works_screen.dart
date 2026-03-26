import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/generation_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/image_utils.dart';
import '../../utils/date_utils.dart' as date_utils;
import 'package:cached_network_image/cached_network_image.dart';

/// 作品页面
class WorksScreen extends StatefulWidget {
  const WorksScreen({super.key});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenerationProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('我的作品'),
      ),
      body: Consumer<GenerationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(message: '加载中...');
          }

          if (provider.history.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.palette_outlined,
              title: '暂无作品',
              subtitle: '快去创作你的第一张AI换脸照片吧',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final item = provider.history[index];
              final imageUrl = ImageUtils.imgUrl(item.resultImage);
              return GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.surfaceBackground,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.surfaceBackground,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
