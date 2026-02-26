import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:url_launcher/url_launcher.dart';

class WindowsWebViewWidget extends StatefulWidget {
  final String htmlContent;
  const WindowsWebViewWidget({super.key, required this.htmlContent});

  @override
  State<WindowsWebViewWidget> createState() => _WindowsWebViewWidgetState();
}

class _WindowsWebViewWidgetState extends State<WindowsWebViewWidget> {
  final _controller = WebviewController();
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  Future<void> _initWebview() async {
    debugPrint('[AdWidget] Initializing Windows WebView...');
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.clearCache();
      await _controller.clearCookies();

      debugPrint('[AdWidget] Loading Windows HTML...');
      if (!mounted) return;
      await _controller.loadStringContent(widget.htmlContent);

      _controller.url.listen((url) {
        if (url != 'about:blank' && !url.contains('data:text/html') && !url.contains('acceptable.a-ads.com')) {
             _launchUrl(url);
             // Reload content to keep ad visible if user navigates away
             _controller.loadStringContent(widget.htmlContent);
        }
      });

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      final msg = 'WebView Initialization Failed: $e';
      debugPrint('[AdWidget] $msg');
      if (mounted) setState(() => _errorMessage = msg);
    }
  }

  void _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    try {
      if (_isInitialized) {
         _controller.stop();
      }
      _controller.dispose();
    } catch (e) {
      // Ignore
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (!_isInitialized) {
      return const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text("Loading Ad..."),
        ],
      ));
    }
    return Container(
      color: Colors.transparent,
      child: Webview(_controller),
    );
  }
}
