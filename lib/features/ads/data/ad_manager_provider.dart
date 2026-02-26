import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/ads/model/ad_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ad_manager_provider.g.dart';

@Riverpod(keepAlive: true)
class AdManager extends _$AdManager {
  final Dio _dio = Dio();
  static const _url =
      'https://gist.githubusercontent.com/mobinsamadir/037cdab8b8713e1c5a52d815539f5638/raw/086833a97d236d9cf57d427c46c2268904244a7e/ad_config.json';
  static const _cacheKey = 'ad_config_cache';
  static const _timestampKey = 'ad_config_last_fetch_timestamp';

  void _log(String message) {
    Logger.app.info(message);
    if (!kIsWeb && Platform.isWindows) {
      stdout.writeln('[AdManager] $message');
    }
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.app.error(message, error, stackTrace);
    if (!kIsWeb && Platform.isWindows) {
      stdout.writeln('[AdManager] ERROR: $message\n$error\n$stackTrace');
    }
  }

  @override
  FutureOr<AdConfig?> build() async {
    // Load SharedPreferences via ref
    final prefs = await ref.watch(sharedPreferencesProvider.future);

    // Try to load cached config
    final cached = prefs.getString(_cacheKey);
    AdConfig? cachedConfig;
    if (cached != null) {
      try {
        final fixedCached = _fixUrls(cached);
        final json = jsonDecode(fixedCached) as Map<String, dynamic>;
        cachedConfig = AdConfig.fromJson(json);
        _log('Loaded ad config from cache.');
      } catch (e) {
        _logError('Failed to parse cached ad config', e);
      }
    }

    // Determine if we need to fetch remote config
    final lastFetch = prefs.getInt(_timestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastFetch;
    final shouldFetch = diff > const Duration(hours: 6).inMilliseconds;

    if (shouldFetch) {
        _log('Ad config cache expired (last fetch: ${DateTime.fromMillisecondsSinceEpoch(lastFetch)}), fetching remote...');
       _fetchAndCache(prefs);
    } else {
        _log('Ad config cache valid (last fetch: ${DateTime.fromMillisecondsSinceEpoch(lastFetch)}). Skipping remote fetch.');
    }

    // If no cache exists, force fetch even if timestamp says otherwise (edge case)
    if (cachedConfig == null && !shouldFetch) {
        _log('No cached ad config found, fetching remote...');
        _fetchAndCache(prefs);
    }

    return cachedConfig;
  }

  Future<void> _fetchAndCache(SharedPreferences prefs) async {
    _log('Attempting to fetch Ad JSON from $_url');
    if (!kIsWeb && Platform.isWindows) {
      stdout.writeln('[NETWORK] Requesting: $_url');
    }
    try {
      final response = await _dio.get<String>(
        _url,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (!kIsWeb && Platform.isWindows) {
        stdout.writeln('[NETWORK] Status: ${response.statusCode}');
        if (response.data != null) {
          final body = response.data!;
          final snapshot = body.substring(0, min(body.length, 100));
          stdout.writeln('[NETWORK] Raw Body Snapshot: $snapshot');
        }
      }

      _log('Network Response received: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data!;
        _log('Raw data received (length: ${rawData.length})');

        final fixedData = _fixUrls(rawData);

        _log('Ad JSON fetched successfully.');

        // Update cache
        await prefs.setString(_cacheKey, fixedData);
        await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);

        // Parse and update state
        try {
          final json = jsonDecode(fixedData) as Map<String, dynamic>;
          _log('JSON parsing result: Success');
          final newConfig = AdConfig.fromJson(json);
          state = AsyncData(newConfig);
        } catch (e) {
           _logError('JSON parsing result: Failure', e);
        }

      } else {
        _logError('Failed to fetch remote ad config. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logError('Error fetching remote ad config', e, stackTrace);
    }
  }

  String _fixUrls(String content) {
    return content
        .replaceAll("src='//", "src='https://")
        .replaceAll('src="//', 'src="https://');
  }
}
