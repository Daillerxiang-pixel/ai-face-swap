import 'package:flutter/material.dart';
import '../../config/theme.dart';

class VipScreen extends StatelessWidget {
  const VipScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VIP Center'), backgroundColor: AppTheme.cardBackground),
      body: const Center(child: Text('VIP Center - Coming Soon', style: TextStyle(color: AppTheme.textSecondary))),
    );
  }
}
