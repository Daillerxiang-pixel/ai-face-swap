import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../config/theme.dart';
import '../utils/image_utils.dart';

/// 图片预览组件
class ImagePreview extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  final String? heroTag;

  const ImagePreview({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
  });

  /// 显示单张图片预览
  static void show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            ImagePreview(
          images: images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImages =
        images.map((e) => ImageUtils.imgUrl(e)).where((e) => e.isNotEmpty).toList();

    if (resolvedImages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Icon(Icons.broken_image, color: context.appColors.textTertiary, size: 48),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PhotoViewGallery.builder(
        pageController: PageController(initialPage: initialIndex),
        itemCount: resolvedImages.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(resolvedImages[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: heroTag != null
                ? PhotoViewHeroAttributes(tag: heroTag!)
                : null,
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
