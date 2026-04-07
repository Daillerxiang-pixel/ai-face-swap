import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 列表/卡片内：静音、循环、自动播放（适合多格缩略预览）
class MutedAutoplayVideoPreview extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const MutedAutoplayVideoPreview({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  State<MutedAutoplayVideoPreview> createState() =>
      _MutedAutoplayVideoPreviewState();
}

class _MutedAutoplayVideoPreviewState extends State<MutedAutoplayVideoPreview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) {
      if (mounted) setState(() => _error = true);
      return;
    }
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = c;
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
      await c.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error || _controller == null) {
      return ColoredBox(
        color: Colors.black26,
        child: Icon(Icons.videocam_off_outlined,
            color: Colors.white.withOpacity(0.5), size: 32),
      );
    }
    if (!_ready) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final c = _controller!;
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}
