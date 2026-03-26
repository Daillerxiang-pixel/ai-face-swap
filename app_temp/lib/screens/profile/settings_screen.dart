import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), backgroundColor: AppTheme.cardBackground),
      body: const Center(child: Text('设置 - 开发中', style: TextStyle(color: AppTheme.textSecondary))),
    );
  }
}
