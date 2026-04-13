import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';

/// 应用内 WebView 页面，用于显示 FAQ / 隐私政策 / 服务条款等
///
/// 支持两种加载方式：
/// - [assetPath] 不为空时，优先从本地 asset 加载 HTML
/// - [url] 不为空时，从网络加载
class WebViewScreen extends StatefulWidget {
  final String title;
  final String? url;
  final String? assetPath;

  const WebViewScreen({
    super.key,
    required this.title,
    this.url,
    this.assetPath,
  }) : assert(url != null || assetPath != null);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1a1a2e))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          if (widget.assetPath != null) return;
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
      ));
    _load();
  }

  Future<void> _load() async {
    if (widget.assetPath != null) {
      try {
        final html = await rootBundle.loadString(widget.assetPath!);
        await _controller.loadHtmlString(html);
      } catch (_) {
        if (widget.url != null) {
          await _controller.loadRequest(Uri.parse(widget.url!));
        } else if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } else {
      await _controller.loadRequest(Uri.parse(widget.url!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: AppTheme.primary, size: 28),
              Text('Back',
                  style: TextStyle(color: AppTheme.primary, fontSize: 17)),
            ],
          ),
        ),
        title: Text(widget.title),
        backgroundColor: context.appColors.background,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 48, color: context.appColors.textTertiary),
                  const SizedBox(height: 12),
                  Text('Failed to load page',
                      style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 16)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                      });
                      _load();
                    },
                    child: const Text('Retry',
                        style:
                            TextStyle(color: AppTheme.primary, fontSize: 15)),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
        ],
      ),
    );
  }
}
