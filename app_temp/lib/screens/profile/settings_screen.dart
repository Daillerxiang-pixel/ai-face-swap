import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/theme.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _autoSave = true;
  String _saveQuality = 'HD';
  bool _pushNotif = true;
  bool _emailNotif = false;

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: _buildBackButton(),
        title: const Text('Settings'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Account
          _buildGroupTitle('ACCOUNT'),
          _buildMenuList([
            _MenuItem(icon: Icons.person_outline, label: 'Profile', iconColor: Colors.purple, iconBg: const Color(0x1E7C3AED)),
            _MenuItem(icon: Icons.workspace_premium_outlined, label: 'Subscription', iconColor: const Color(0xFFF59E0B), iconBg: const Color(0x26F59E0B)),
          ]),
          const SizedBox(height: 24),

          // Preferences
          _buildGroupTitle('PREFERENCES'),
          _buildMenuList([
            _MenuItem(icon: Icons.dark_mode_outlined, label: 'Dark Mode', toggle: true, toggleValue: _darkMode, onToggle: (v) => setState(() => _darkMode = v), iconColor: const Color(0xFF3B82F6), iconBg: const Color(0x1E3B82F6)),
            _MenuItem(icon: Icons.save_outlined, label: 'Auto-Save', toggle: true, toggleValue: _autoSave, onToggle: (v) => setState(() => _autoSave = v), iconColor: AppTheme.primary, iconBg: const Color(0x1E7C3AED)),
            _MenuItem(icon: Icons.high_quality_outlined, label: 'Save Quality', value: _saveQuality, iconColor: const Color(0xFF34C759), iconBg: const Color(0x2634C759)),
          ]),
          const SizedBox(height: 24),

          // Notifications
          _buildGroupTitle('NOTIFICATIONS'),
          _buildMenuList([
            _MenuItem(icon: Icons.notifications_outlined, label: 'Push Notifications', toggle: true, toggleValue: _pushNotif, onToggle: (v) => setState(() => _pushNotif = v), iconColor: const Color(0xFF3B82F6), iconBg: const Color(0x1E3B82F6)),
            _MenuItem(icon: Icons.email_outlined, label: 'Email Notifications', toggle: true, toggleValue: _emailNotif, onToggle: (v) => setState(() => _emailNotif = v), iconColor: AppTheme.textSecondary, iconBg: const Color(0x1E8E8E93)),
          ]),
          const SizedBox(height: 24),

          // Support
          _buildGroupTitle('SUPPORT'),
          _buildMenuList([
            _MenuItem(icon: Icons.help_outline, label: 'FAQ', iconColor: const Color(0xFF3B82F6), iconBg: const Color(0x1E3B82F6)),
            _MenuItem(icon: Icons.headset_mic_outlined, label: 'Contact Us', iconColor: AppTheme.primary, iconBg: const Color(0x1E7C3AED)),
            _MenuItem(icon: Icons.description_outlined, label: 'Terms of Service', iconColor: AppTheme.textSecondary, iconBg: const Color(0x1E8E8E93)),
            _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', iconColor: AppTheme.textSecondary, iconBg: const Color(0x1E8E8E93)),
          ]),
          const SizedBox(height: 24),

          // Danger
          _buildMenuList([
            _MenuItem(icon: Icons.delete_outline, label: 'Delete Account', isDanger: true, iconColor: const Color(0xFFFF3B30), iconBg: const Color(0x1EFF3B30)),
          ]),
          const SizedBox(height: 16),

          // Version
          Center(
            child: Text(
              'AI FaceSwap v$_appVersion',
              style: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
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

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: e.key == 0 ? const Radius.circular(20) : Radius.zero,
                  bottom: isLast ? const Radius.circular(20) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 17),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: item.isDanger ? const Color(0xFFFF3B30) : AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      if (item.value != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            item.value!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (item.toggle)
                        _buildToggle(item.toggleValue ?? false, item.onToggle ?? (_) {})
                      else
                        const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 18),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 0.5, color: AppTheme.surfaceBackground),
                ),
            ],
          );
        }).toList()),
      ),
    );
  }

  Widget _buildToggle(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? AppTheme.primary : AppTheme.surfaceBackground,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? value;
  final bool toggle;
  final bool? toggleValue;
  final Function(bool)? onToggle;
  final VoidCallback? onTap;
  final bool isDanger;
  final Color iconColor;
  final Color iconBg;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.value,
    this.toggle = false,
    this.toggleValue,
    this.onToggle,
    this.onTap,
    this.isDanger = false,
    this.iconColor = AppTheme.textSecondary,
    this.iconBg = const Color(0x1E8E8E93),
  });
}
