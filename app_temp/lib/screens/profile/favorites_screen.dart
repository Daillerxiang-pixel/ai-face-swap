import 'package:flutter/material.dart';
import '../../config/theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏'), backgroundColor: AppTheme.cardBackground),
      body: const Center(child: Text('我的收藏 - 开发中', style: TextStyle(color: AppTheme.textSecondary))),
    );
  }
}
