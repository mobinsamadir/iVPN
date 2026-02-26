import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/features/ads/model/ad_config.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BannerAdWidget extends HookWidget {
  const BannerAdWidget({
    super.key,
    required this.adItem,
  });

  final AdItem adItem;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() {
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));

      String content = adItem.mediaSource;

      // Fix protocol-relative URLs in iframes
      if (content.contains("src='//")) {
        content = content.replaceAll("src='//", "src='https://");
      }
      if (content.contains('src="//')) {
        content = content.replaceAll('src="//', 'src="https://');
      }

      // Check if content is a URL or HTML fragment
      final bool isUrl = content.startsWith('http') || (content.startsWith('//') && !content.contains('<'));

      if (isUrl) {
        if (content.startsWith('//')) {
          content = 'https:$content';
        }
        c.loadRequest(Uri.parse(content));
      } else {
        // Wrap HTML content in boilerplate
        final fullHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0; padding:0; background-color:transparent; display:flex; justify-content:center; align-items:center; height: 100vh; overflow: hidden;">
  $content
</body>
</html>
''';
        c.loadHtmlString(fullHtml);
      }
      return c;
    }, [adItem.mediaSource]);

    // Height constraint is now handled by the parent widget (HomePage)
    return SizedBox(
      width: double.infinity,
      child: WebViewWidget(controller: controller),
    );
  }
}
