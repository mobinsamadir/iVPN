import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vpn_config_provider.g.dart';

final vpnConfigProvider = StateProvider<String?>((ref) => null);

@Riverpod(keepAlive: true)
VpnConfigService vpnConfigService(Ref ref) {
  return VpnConfigService(ref);
}

class VpnConfigService {
  final Ref _ref;
  final Dio _dio = Dio();
  static const _url =
      'https://gist.githubusercontent.com/mobinsamadir/687a7ef199d6eaf6d1912e36151a9327/raw/a1e99f7ce01dcc0ee065552cdcc13593de1cd888/servers.txt';

  VpnConfigService(this._ref);

  Future<String?> fetchConfig() async {
    Logger.bootstrap.info('Fetching initial config from remote source...');
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

      if (response.statusCode == 200 && response.data != null) {
        _ref.read(vpnConfigProvider.notifier).state = response.data;
        Logger.bootstrap.info('Initial config fetched successfully.');
        return response.data;
      } else {
        Logger.bootstrap.warning('Failed to fetch initial config. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.bootstrap.error('Error fetching initial config', e, stackTrace);
    }
    return null;
  }
}
