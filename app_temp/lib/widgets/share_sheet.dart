import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';

/// 分享面板 — 底部弹出
class ShareSheet {
  /// 分享内容（图片 URL + 文字）
  static void show(BuildContext context, {String? text, String? imageUrl}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _ShareSheetContent(text: text, imageUrl: imageUrl),
    );
  }

  /// 直接分享（无需弹面板）
  static Future<void> share({String? text, String? imageUrl}) async {
    final xfile = imageUrl != null ? XFile(imageUrl) : null;
    if (xfile != null) {
      await Share.shareXFiles(
        [xfile],
        text: text ?? 'Check out this amazing AI FaceSwap!',
      );
    } else {
      await Share.share(text ?? 'Check out this amazing AI FaceSwap!');
    }
  }
}

class _ShareSheetContent extends StatelessWidget {
  final String? text;
  final String? imageUrl;

  const _ShareSheetContent({this.text, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceBackground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share',
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShareOption(
                  label: 'Instagram',
                  gradient: const [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _shareTo(context, 'instagram'),
                ),
                _ShareOption(
                  label: 'TikTok',
                  gradient: const [Color(0xFF010101), Color(0xFF333333)],
                  icon: Icons.music_note,
                  border: true,
                  onTap: () => _shareTo(context, 'tiktok'),
                ),
                _ShareOption(
                  label: 'WhatsApp',
                  gradient: const [Color(0xFF25D366), Color(0xFF25D366)],
                  icon: Icons.chat_bubble,
                  onTap: () => _shareTo(context, 'whatsapp'),
                ),
                _ShareOption(
                  label: 'Message',
                  gradient: const [Color(0xFF7C3AED), Color(0xFF7C3AED)],
                  icon: Icons.send,
                  onTap: () => _shareTo(context, 'message'),
                ),
                _ShareOption(
                  label: 'More',
                  gradient: const [Color(0xFF2C2C2E), Color(0xFF2C2C2E)],
                  icon: Icons.more_horiz,
                  iconColor: context.appColors.textSecondary,
                  onTap: () => _shareTo(context, 'more'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Cancel
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.appColors.surfaceBackground,
                  foregroundColor: context.appColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide.none,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareTo(BuildContext context, String platform) async {
    Navigator.of(context).pop(); // 关闭面板
    final shareText = text ?? 'Check out this amazing AI FaceSwap!';
    final xfile = imageUrl != null ? XFile(imageUrl!) : null;

    if (xfile != null) {
      await Share.shareXFiles([xfile], text: shareText);
    } else {
      await Share.share(shareText);
    }
  }
}

class _ShareOption extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final IconData icon;
  final bool border;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ShareOption({
    required this.label,
    required this.gradient,
    required this.icon,
    this.border = false,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: gradient,
              ),
              border: border
                  ? Border.all(color: context.appColors.surfaceBackground)
                  : null,
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
