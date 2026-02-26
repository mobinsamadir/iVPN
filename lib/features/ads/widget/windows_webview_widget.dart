import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';

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

  void _log(String message) {
    debugPrint(message);
    if (!kIsWeb && Platform.isWindows) {
      stdout.writeln('[WindowsWebViewWidget] $message');
    }
  }

  Future<void> _initWebview() async {
    _log('Initializing Windows WebView...');
    try {
      // Check for WebView2 Runtime
      // Note: WebviewController doesn't have a static check method readily available in all versions,
      // but initialization throws if runtime is missing.
      // However, we will try to use initialize() safely.

      await _controller.initialize();
      _log('WebView controller initialized.');

      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.clearCache();
      await _controller.clearCookies();

      _log('Loading HTML content...');
      if (!mounted) return;
      await _controller.loadStringContent(widget.htmlContent);
      _log('HTML content loaded.');

      _controller.url.listen((url) {
        if (url != 'about:blank' && !url.contains('data:text/html') && !url.contains('acceptable.a-ads.com')) {
             _launchUrl(url);
             // Reload content to keep ad visible if user navigates away
             _controller.loadStringContent(widget.htmlContent);
        }
      });

      if (mounted) setState(() => _isInitialized = true);
    } catch (e, stackTrace) {
      final msg = 'WebView Initialization Failed: $e';
      _log('ERROR: $msg\n$stackTrace');

      if (mounted) setState(() => _errorMessage = "Ad View Error");
    }
  }

  Future<void> _launchUrl(String urlString) async {
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Ad View Error",
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        )
      );
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
    return ColoredBox(
      color: Colors.transparent,
      child: Webview(_controller),
    );
  }
}
