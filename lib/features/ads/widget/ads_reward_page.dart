import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/ads/data/ad_manager_provider.dart';
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

      // If iframe/div, wrap in HTML
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
         if (content.startsWith('//')) {
             content = 'https:$content';
         }
         // Only load if it looks like a URL
         if (content.startsWith('http')) {
             c.loadRequest(Uri.parse(content));
         } else {
             // Fallback for empty or invalid content not handled above
             c.loadHtmlString(content);
         }
      }
      return c;
    }, [rewardAd?.mediaSource]);

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

    // Prevent back navigation without result (treat as cancel)
    // Actually, PopScope with canPop: false allows intercepting.
    // But we want to allow pop, just ensure it returns false if not claimed.
    // However, Navigator.pop(result) returns result. Back button returns null.
    // So we can wrap in PopScope, intercept back, and pop(false).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If user presses back, we treat it as cancel (false)
        Navigator.of(context).pop(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("iVPN Rewards"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: WebViewWidget(controller: controller),
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
