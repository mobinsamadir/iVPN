import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/config_injection/data/vpn_config_provider.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initial_config_service.g.dart';

@Riverpod(keepAlive: true)
InitialConfigService initialConfigService(Ref ref) {
  return InitialConfigService(ref);
}

class InitialConfigService {
  final Ref _ref;

  InitialConfigService(this._ref);

  Future<void> injectInitialConfig() async {
    final isFirstLaunch = _ref.read(Preferences.isFirstLaunch);
    Logger.bootstrap.info('Checking for first launch configs... (isFirstLaunch: $isFirstLaunch)');

    if (!isFirstLaunch) {
      Logger.bootstrap.debug('Not first launch, skipping initial config injection.');
      return;
    }

    Logger.bootstrap.info('First launch detected, attempting to inject initial config...');

    try {
      final configContent = await _ref.read(vpnConfigServiceProvider).fetchConfig();

      if (configContent != null && configContent.isNotEmpty) {
        final profileRepo = _ref.read(profileRepositoryProvider).requireValue;

        // Inject the config
        final result = await profileRepo.addLocal(
          configContent,
          userOverride: const UserOverride(name: "iVPN Free Servers"),
        ).run();

        result.match(
          (err) {
             Logger.bootstrap.error('Failed to inject initial config: $err');
          },
          (_) async {
            Logger.bootstrap.info('Initial config injected successfully.');
            // Set isFirstLaunch to false
             await _ref.read(Preferences.isFirstLaunch.notifier).update(false);
          },
        );
      } else {
        Logger.bootstrap.warning('Failed to fetch initial config.');
      }
    } catch (e, stackTrace) {
      Logger.bootstrap.error('Error injecting initial config', e, stackTrace);
      // We do not rethrow, to avoid blocking app startup
    }
  }
}
