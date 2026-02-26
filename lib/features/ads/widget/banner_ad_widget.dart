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

      // If it's an iframe, wrap it in HTML
      if (content.trim().startsWith('<iframe') || content.trim().startsWith('<div')) {
          c.loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>body { margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; background-color: transparent; overflow: hidden; }</style>
</head>
<body>
$content
</body>
</html>
        ''');
      } else {
        // Assume URL
        if (content.startsWith('//')) {
            content = 'https:$content';
        }
        c.loadRequest(Uri.parse(content));
      }
      return c;
    }, [adItem.mediaSource]);

    final height = MediaQuery.of(context).size.height * (adItem.heightFactor ?? 0.15);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: WebViewWidget(controller: controller),
    );
  }
}
