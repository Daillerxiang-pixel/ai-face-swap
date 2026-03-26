import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../widgets/loading_widget.dart';

/// 生成结果页面
class ResultScreen extends StatefulWidget {
  final Template template;
  final String sourceImagePath;

  const ResultScreen({
    super.key,
    required this.template,
    required this.sourceImagePath,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isGenerating = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _simulateGeneration();
  }

  /// 模拟生成过程
  Future<void> _simulateGeneration() async {
    // 实际应轮询 API 查询生成状态
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isGenerating = false;
        // 模拟成功
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('生成结果'),
      ),
      body: _isGenerating
          ? const LoadingWidget(message: 'AI正在生成中，请稍候...')
          : _buildResult(),
      bottomNavigationBar: _isGenerating
          ? null
          : SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
                child: Row(
                  children: [
                    // 保存按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download_outlined,
                                  color: AppTheme.textPrimary,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '保存图片',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 分享按钮
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: MaterialButton(
                          onPressed: () {},
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.share,
                                color: AppTheme.textPrimary,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '分享',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 结果展示
  Widget _buildResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 生成成功提示
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '生成完成',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '长按图片可保存到相册',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            // 对比展示
            Row(
              children: [
                Expanded(
                  child: _buildImageCard('原图', widget.sourceImagePath, isLocal: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageCard('效果图', null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 图片卡片
  Widget _buildImageCard(String label, String? path, {bool isLocal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: path != null
                ? Image.file(
                    File(path),
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 40,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
