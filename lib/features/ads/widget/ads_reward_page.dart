import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/ads/data/ad_manager_provider.dart';
import 'package:hiddify/features/ads/widget/windows_webview_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdsRewardPage extends HookConsumerWidget {
  const AdsRewardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adConfig = ref.watch(adManagerProvider).asData?.value;
    final rewardAd = adConfig?.ads.rewardAd;
    // Default to 10 seconds if not loaded yet or configured
    final initialTimer = rewardAd?.timerSeconds ?? 10;

    final countdownTimer = useState(initialTimer);
    final canClaim = useState(false);

    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    Widget webViewWidget;

    if (isDesktop) {
       if (Platform.isWindows) {
         String content = rewardAd?.mediaSource ?? '';

         if (content.isEmpty) {
            content = '<html><body></body></html>';
         }

          // Fix protocol-relative URLs
          if (content.contains("src='//")) {
            content = content.replaceAll("src='//", "src='https://");
          }
          if (content.contains('src="//')) {
            content = content.replaceAll('src="//', 'src="https://');
          }

          final bool isUrl = content.startsWith('http') || (content.startsWith('//') && !content.contains('<'));
          String fullHtml;

          if (isUrl) {
            if (content.startsWith('//')) {
              content = 'https:$content';
            }
            fullHtml = '<iframe src="$content" style="border:0; width:100%; height:100%; overflow:hidden;" allow="autoplay"></iframe>';
          } else {
            fullHtml = content;
          }

          if (!fullHtml.contains("<html")) {
             fullHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0; padding:0; background-color:transparent; display:flex; justify-content:center; align-items:center; height: 100vh; overflow: hidden;">
  $fullHtml
</body>
</html>
''';
          }

         webViewWidget = WindowsWebViewWidget(htmlContent: fullHtml);
       } else {
         webViewWidget = const Center(child: Text("Ads not supported on this platform"));
       }
    } else {
        final controller = useMemoized(() {
          final c = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000));

          String content = rewardAd?.mediaSource ?? '';

          if (content.isEmpty) {
            c.loadHtmlString('<html><body></body></html>');
            return c;
          }

          // Fix protocol-relative URLs
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
        }, [rewardAd?.mediaSource]);
        webViewWidget = WebViewWidget(controller: controller);
    }

    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdownTimer.value > 0) {
          countdownTimer.value--;
        } else {
          canClaim.value = true;
          timer.cancel();
          // Auto-pop with true when timer ends
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      });
      return t.cancel;
    }, []);

    // Removed PopScope(canPop: false) to prevent navigation lock.
    // Default back button returns null, which ConnectionButton treats as cancel (not true).
    return Scaffold(
      appBar: AppBar(
        title: const Text("iVPN Rewards"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: webViewWidget,
              ),
              const Gap(16),
              const Text(
                "Please wait to connect...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              if (!canClaim.value)
                Text(
                  "${countdownTimer.value} seconds",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}
