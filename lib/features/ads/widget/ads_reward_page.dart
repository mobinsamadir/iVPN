import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/ads/data/ad_config_provider.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdsRewardPage extends HookConsumerWidget {
  const AdsRewardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final countdownTimer = useState(5);
    final canClaim = useState(false);
    final controller = useMemoized(() {
      return WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; background-color: transparent;">
<div id="frame" style="width: 100%;margin: auto;position: relative; z-index: 99998;">
  <iframe data-aa='2426527' src='https://acceptable.a-ads.com/2426527/?size=Adaptive' style='border:0; padding:0; width:70%; height:300px; overflow:hidden;display: block;margin: auto'></iframe>
</div>
</body>
</html>
        ''');
    });

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
                        final configContent = ref.read(adConfigProvider);
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
                          ref.read(adConfigServiceProvider).fetchRemoteConfig();
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
