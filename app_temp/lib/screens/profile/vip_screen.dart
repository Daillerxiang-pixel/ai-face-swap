import 'package:flutter/material.dart';
import '../../config/theme.dart';

class VipScreen extends StatelessWidget {
  const VipScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('VIP Center'), backgroundColor: context.appColors.cardBackground),
      body: Center(child: Text('VIP Center - Coming Soon', style: TextStyle(color: context.appColors.textSecondary))),
    );
  }
}
