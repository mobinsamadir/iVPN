import 'dart:async';
import 'dart:convert';

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
        Logger.bootstrap.debug('Loaded ad config from cache.');
      } catch (e) {
        Logger.bootstrap.warning('Failed to parse cached ad config: $e');
      }
    }

    // Trigger fetch in background to update cache
    _fetchAndCache(prefs);

    return cachedConfig;
  }

  Future<void> _fetchAndCache(SharedPreferences prefs) async {
    Logger.bootstrap.debug('Fetching remote ad config...');
    try {
      final response = await _dio.get<String>(
        _url,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data!;
        final fixedData = _fixUrls(rawData);

        // Update cache
        await prefs.setString(_cacheKey, fixedData);

        // Parse and update state
        final json = jsonDecode(fixedData) as Map<String, dynamic>;
        final newConfig = AdConfig.fromJson(json);

        Logger.bootstrap.debug('Remote ad config fetched and cached successfully.');
        state = AsyncData(newConfig);
      } else {
        Logger.bootstrap.warning('Failed to fetch remote ad config. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.bootstrap.error('Error fetching remote ad config', e, stackTrace);
    }
  }

  String _fixUrls(String content) {
    return content
        .replaceAll("src='//", "src='https://")
        .replaceAll('src="//', 'src="https://');
  }
}
