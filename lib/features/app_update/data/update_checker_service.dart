import 'package:dio/dio.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/features/app_update/model/custom_version_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_checker_service.g.dart';

@Riverpod(keepAlive: true)
UpdateCheckerService updateCheckerService(Ref ref) {
  return UpdateCheckerService(ref);
}

class UpdateCheckerService {
  final Ref _ref;
  final Dio _dio = Dio();
  static const _url = 'https://gist.githubusercontent.com/mobinsamadir/61a698197a1f276e3fef1376ff3f9b38/raw/730a41b8eca4eecd882a42f066f4ba56098c6187/version.ivpn.json';

  UpdateCheckerService(this._ref);

  Future<CustomVersionEntity?> checkUpdate() async {
    Logger.bootstrap.debug('Checking for updates...');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _url,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final version = CustomVersionEntity.fromJson(response.data!);
        Logger.bootstrap.debug('Update info fetched successfully: ${version.latestVersionName}');
        return version;
      } else {
        Logger.bootstrap.warning('Failed to fetch update info. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.bootstrap.error('Error fetching update info', e, stackTrace);
    }
    return null;
  }
}
