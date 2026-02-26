import 'package:dio/dio.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ad_config_provider.g.dart';

// Provider to store the fetched config content
final adConfigProvider = StateProvider<String?>((ref) => null);

@Riverpod(keepAlive: true)
AdConfigService adConfigService(Ref ref) {
  return AdConfigService(ref);
}

class AdConfigService {
  final Ref _ref;
  final Dio _dio = Dio();
  static const _url =
      'https://gist.githubusercontent.com/mobinsamadir/687a7ef199d6eaf6d1912e36151a9327/raw/a1e99f7ce01dcc0ee065552cdcc13593de1cd888/servers.txt';

  AdConfigService(this._ref);

  Future<void> fetchRemoteConfig() async {
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
        _ref.read(adConfigProvider.notifier).state = response.data;
        Logger.bootstrap.debug('Remote ad config fetched successfully.');
      } else {
        Logger.bootstrap.warning('Failed to fetch remote ad config. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.bootstrap.error('Error fetching remote ad config', e, stackTrace);
      // We do not rethrow, to avoid blocking app startup
    }
  }
}
