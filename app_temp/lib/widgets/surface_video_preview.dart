import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 详情/上传区：进入后自动播放、有声、循环，BoxFit.cover 铺满
class SurfaceVideoPreview extends StatefulWidget {
  final String url;
  final double? height;
  final BorderRadius? borderRadius;

  const SurfaceVideoPreview({
    super.key,
    required this.url,
    this.height,
    this.borderRadius,
  });

  @override
  State<SurfaceVideoPreview> createState() => _SurfaceVideoPreviewState();
}

class _SurfaceVideoPreviewState extends State<SurfaceVideoPreview> {
  VideoPlayerController? _c;
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
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.setLooping(true);
      await controller.play();
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
      await controller.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _c;
    if (c == null || !_ready) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_error) {
      child = ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Icon(Icons.videocam_off_outlined,
              color: Colors.white.withOpacity(0.5), size: 40),
        ),
      );
    } else if (!_ready || _c == null) {
      child = const ColoredBox(
        color: Colors.black12,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    } else {
      final c = _c!;
      child = GestureDetector(
        onTap: _toggle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
            if (!c.value.isPlaying)
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ),
          ],
        ),
      );
    }

    if (widget.height != null) {
      child = SizedBox(height: widget.height, width: double.infinity, child: child);
    } else {
      child = SizedBox.expand(child: child);
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }
}
