import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/ads/data/ad_manager_provider.dart';
import 'package:hiddify/features/config_injection/data/vpn_config_provider.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdsRewardPage extends HookConsumerWidget {
  const AdsRewardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final adConfig = ref.watch(adManagerProvider).asData?.value;
    final rewardAd = adConfig?.ads.rewardAd;
    // Default to 10 seconds if not loaded yet
    final initialTimer = rewardAd?.timerSeconds ?? 10;

    final countdownTimer = useState(initialTimer);
    final canClaim = useState(false);

    final controller = useMemoized(() {
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));

      String content = rewardAd?.mediaSource ?? '';

      if (content.isEmpty) {
         c.loadHtmlString('''
<!DOCTYPE html>
<html>
<body>
</body>
</html>
''');
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

    // Ensure we fetch VPN config if not present
    useEffect(() {
        if (ref.read(vpnConfigProvider) == null) {
            ref.read(vpnConfigServiceProvider).fetchConfig();
        }
        return null;
    }, []);

    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (canClaim.value) {
          timer.cancel();
          return;
        }
        if (countdownTimer.value > 0) {
          countdownTimer.value--;
        } else {
          canClaim.value = true;
          timer.cancel();
        }
      });
      return t.cancel;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("iVPN Rewards"),
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
              "برای دریافت ۱ ساعت اتصال رایگان، لطفاً صبر کنید...",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const Gap(8),
            if (!canClaim.value)
              Text(
                "${countdownTimer.value} ثانیه",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canClaim.value
                    ? () async {
                        final configContent = ref.read(vpnConfigProvider);
                        if (configContent == null || configContent.isEmpty) {
                          if (context.mounted) {
                            toastification.show(
                              context: context,
                              title: const Text('خطا در دریافت تنظیمات. لطفاً اینترنت خود را بررسی کنید.'),
                              type: ToastificationType.error,
                              autoCloseDuration: const Duration(seconds: 4),
                            );
                          }
                          // Try fetching again
                          ref.read(vpnConfigServiceProvider).fetchConfig();
                          return;
                        }

                        try {
                           final profileRepo = ref.read(profileRepositoryProvider).requireValue;
                           final result = await profileRepo.addLocal(configContent).run();

                           result.match(
                             (err) {
                               if (context.mounted) {
                                 toastification.show(
                                   context: context,
                                   title: Text('خطا در افزودن پروفایل: ${err.present(t).type}'),
                                   type: ToastificationType.error,
                                   autoCloseDuration: const Duration(seconds: 4),
                                 );
                               }
                             },
                             (_) {
                               if (context.mounted) {
                                 toastification.show(
                                   context: context,
                                   title: const Text('پاداش دریافت شد! کانفیگ‌ها اضافه شدند.'),
                                   type: ToastificationType.success,
                                   autoCloseDuration: const Duration(seconds: 4),
                                 );
                                 Navigator.of(context).pop();
                               }
                             }
                           );
                        } catch (e) {
                          if (context.mounted) {
                            toastification.show(
                              context: context,
                              title: Text('خطای غیرمنتظره: $e'),
                              type: ToastificationType.error,
                              autoCloseDuration: const Duration(seconds: 4),
                            );
                          }
                        }
                      }
                    : null,
                child: const Text("🎁 دریافت پاداش (۱ ساعت اتصال)"),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}
