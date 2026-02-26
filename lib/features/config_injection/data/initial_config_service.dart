import 'dart:io';
import 'package:flutter/foundation.dart';
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

  void _log(String message) {
    Logger.bootstrap.info(message);
    if (!kIsWeb && Platform.isWindows) {
      stdout.writeln('[InitialConfigService] $message');
    }
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.bootstrap.error(message, error, stackTrace);
    if (!kIsWeb && Platform.isWindows) {
      stdout.writeln('[InitialConfigService] ERROR: $message\n$error\n$stackTrace');
    }
  }

  Future<void> injectInitialConfig() async {
    final isFirstLaunch = _ref.read(Preferences.isFirstLaunch);
    _log('Checking for first launch configs... (isFirstLaunch: $isFirstLaunch)');

    if (!isFirstLaunch) {
      Logger.bootstrap.debug('Not first launch, skipping initial config injection.');
      return;
    }

    _log('First launch detected, attempting to inject initial config...');

    try {
      _log('Attempting to fetch initial config content...');
      final configContent = await _ref.read(vpnConfigServiceProvider).fetchConfig();

      if (configContent != null && configContent.isNotEmpty) {
        // Log the ENTIRE raw string response to stdout as requested
        if (!kIsWeb && Platform.isWindows) {
          stdout.writeln('[InitialConfigService] Full Raw Response:\n$configContent');
        }

        _log('Config content fetched (length: ${configContent.length}). Injecting...');

        final profileRepo = _ref.read(profileRepositoryProvider).requireValue;

        // Inject the config
        final result = await profileRepo.addLocal(
          configContent,
          userOverride: const UserOverride(name: "iVPN Free Servers"),
        ).run();

        result.match(
          (err) {
             _logError('Failed to inject initial config: $err');
          },
          (_) async {
            _log('Initial config injected successfully.');
            // Set isFirstLaunch to false
             await _ref.read(Preferences.isFirstLaunch.notifier).update(false);
          },
        );
      } else {
        _log('Failed to fetch initial config (content is null or empty).');
      }
    } catch (e, stackTrace) {
      _logError('Error injecting initial config', e, stackTrace);
      // We do not rethrow, to avoid blocking app startup
    }
  }
}
