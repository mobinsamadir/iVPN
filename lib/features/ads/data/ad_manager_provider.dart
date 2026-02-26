import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/features/ads/model/ad_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ad_manager_provider.g.dart';

@Riverpod(keepAlive: true)
class AdManager extends _$AdManager {
  final Dio _dio = Dio();
  static const _url =
      'https://gist.githubusercontent.com/mobinsamadir/037cdab8b8713e1c5a52d815539f5638/raw/086833a97d236d9cf57d427c46c2268904244a7e/ad_config.json';

  @override
  FutureOr<AdConfig?> build() async {
    return _fetchAdConfig();
  }

  Future<AdConfig?> _fetchAdConfig() async {
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
        final json = jsonDecode(response.data!) as Map<String, dynamic>;
        final config = AdConfig.fromJson(json);
        Logger.bootstrap.debug('Remote ad config fetched successfully.');
        return config;
      } else {
        Logger.bootstrap.warning('Failed to fetch remote ad config. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.bootstrap.error('Error fetching remote ad config', e, stackTrace);
    }
    return null;
  }
}
