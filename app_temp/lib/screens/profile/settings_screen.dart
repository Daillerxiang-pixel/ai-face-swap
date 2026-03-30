import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

/// 设置页面 — 昵称/头像/自动保存/主题切换
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSave = true;
  String _appVersion = '';
  final ApiService _api = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    final user = context.read<UserProvider>().user;
    _autoSave = user?.autoSave ?? true;
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  /// Show edit nickname dialog
  void _showEditNickname() {
    final controller = TextEditingController(text: context.read<UserProvider>().user?.nickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Edit Nickname', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter nickname',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surfaceBackground)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await _updateSetting(nickname: name);
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Show avatar picker
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.textTertiary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              title: const Text('Camera', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
              title: const Text('Photo Library', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (image == null) return;

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading avatar...'), duration: Duration(seconds: 30)),
        );
      }

      // Upload image
      final res = await _api.uploadImage(image.path);
      if (!res.success || res.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload avatar')),
          );
        }
        return;
      }
      final data = res.data as Map;
      final url = data['url']?.toString() ?? data['file_path']?.toString() ?? '';
      if (url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload succeeded but no URL returned')),
          );
        }
        return;
      }

      // Update avatar on server
      final success = await _updateSetting(avatar: url);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully'),
              backgroundColor: Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save avatar to profile'),
              backgroundColor: Color(0xFFFF3B30),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload avatar')),
        );
      }
    }
  }

  Future<bool> _updateSetting({String? nickname, String? avatar, bool? autoSave, String? theme}) async {
    setState(() => _isUpdating = true);
    try {
      final success = await context.read<UserProvider>().updateSettings(
        nickname: nickname,
        avatar: avatar,
        autoSave: autoSave,
        theme: theme,
      );
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update setting'),
            backgroundColor: Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return success;
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        leading: _buildBackButton(),
        title: const Text('Settings'),
        backgroundColor: theme.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Account
          _buildGroupTitle('ACCOUNT', theme.textSecondary),
          _buildMenuList([
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Nickname',
              iconColor: Colors.purple,
              iconBg: const Color(0x1E7C3AED),
              value: context.watch<UserProvider>().user?.nickname ?? 'User',
              onTap: _showEditNickname,
            ),
            _MenuItem(
              icon: Icons.camera_alt_outlined,
              label: 'Avatar',
              iconColor: AppTheme.primary,
              iconBg: const Color(0x1E7C3AED),
              value: 'Change',
              onTap: _showAvatarPicker,
            ),
          ], theme.cardBackground),
          const SizedBox(height: 24),

          // Preferences
          _buildGroupTitle('PREFERENCES', theme.textSecondary),
          _buildMenuList([
            _MenuItem(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              toggle: true,
              toggleValue: theme.isDark,
              onToggle: (v) {
                theme.setTheme(v);
              },
              iconColor: const Color(0xFF3B82F6),
              iconBg: const Color(0x1E3B82F6),
            ),
            _MenuItem(
              icon: Icons.save_outlined,
              label: 'Auto-Save Results',
              toggle: true,
              toggleValue: _autoSave,
              onToggle: (v) {
                setState(() => _autoSave = v);
                _updateSetting(autoSave: v);
              },
              iconColor: AppTheme.primary,
              iconBg: const Color(0x1E7C3AED),
            ),
          ], theme.cardBackground),
          const SizedBox(height: 24),

          // Notifications
          _buildGroupTitle('NOTIFICATIONS'),
          _buildMenuList([
            _MenuItem(icon: Icons.notifications_outlined, label: 'Push Notifications', toggle: true, toggleValue: true, onToggle: (_) {}, iconColor: const Color(0xFF3B82F6), iconBg: const Color(0x1E3B82F6)),
            _MenuItem(icon: Icons.email_outlined, label: 'Email Notifications', toggle: true, toggleValue: false, onToggle: (_) {}, iconColor: AppTheme.textSecondary, iconBg: const Color(0x1E8E8E93)),
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
            child: Text('AI FaceSwap v$_appVersion', style: TextStyle(color: context.textTertiaryColor, fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: context.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildMenuList(List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
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
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(7)),
                        child: Icon(item.icon, color: item.iconColor, size: 17),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: item.isDanger ? const Color(0xFFFF3B30) : AppTheme.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (item.value != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(item.value!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
        width: 44, height: 26,
        decoration: BoxDecoration(
          color: value ? AppTheme.primary : AppTheme.surfaceBackground,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22, height: 22,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
