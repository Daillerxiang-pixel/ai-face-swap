import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';

/// 骨架屏加载组件
class ShimmerWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerWidget.rectangular({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  const ShimmerWidget.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.appColors.surfaceBackground,
      highlightColor: context.appColors.cardBackground,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.appColors.surfaceBackground,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// 模板卡片骨架屏
class TemplateCardShimmer extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const TemplateCardShimmer({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerWidget.rectangular(borderRadius: 12),
          ),
          SizedBox(height: 6),
          ShimmerWidget.rectangular(height: 14, borderRadius: 6),
          SizedBox(height: 4),
          ShimmerWidget.rectangular(height: 10, width: 60, borderRadius: 4),
        ],
      ),
    );
  }
}
