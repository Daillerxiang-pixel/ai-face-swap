import 'package:flutter/material.dart';
import '../../config/theme.dart';

class VipScreen extends StatelessWidget {
  const VipScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('会员中心'), backgroundColor: AppTheme.cardBackground),
      body: const Center(child: Text('会员中心 - 开发中', style: TextStyle(color: AppTheme.textSecondary))),
    );
  }
}
