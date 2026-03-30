import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Reusable full-screen video player with controls
class AppVideoPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;

  const AppVideoPlayer({super.key, required this.url, this.autoPlay = true});

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.autoPlay) {
          _controller.play();
          _controller.setLooping(true);
        }
      }
    }).catchError((_) {
      if (mounted) setState(() => _hasError = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text('Failed to load video', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          // Play/pause overlay
          AnimatedOpacity(
            opacity: _controller.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ),
          // Video duration indicator
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: value.duration.inMilliseconds > 0
                            ? value.position.inMilliseconds / value.duration.inMilliseconds
                            : 0.0,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(value.position),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(value.duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final h = d.inHours.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '$m:$s';
  }
}
