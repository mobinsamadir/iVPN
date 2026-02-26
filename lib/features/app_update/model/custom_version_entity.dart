import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_version_entity.freezed.dart';
part 'custom_version_entity.g.dart';

@freezed
class CustomVersionEntity with _$CustomVersionEntity {
  const factory CustomVersionEntity({
    @JsonKey(name: 'latest_version_name') required String latestVersionName,
    @JsonKey(name: 'latest_build_number') required int latestBuildNumber,
    @JsonKey(name: 'is_force_update') @Default(false) bool isForceUpdate,
    @JsonKey(name: 'release_notes') required String releaseNotes,
    @JsonKey(name: 'download_links') required Map<String, String> downloadLinks,
  }) = _CustomVersionEntity;

  factory CustomVersionEntity.fromJson(Map<String, dynamic> json) => _$CustomVersionEntityFromJson(json);
}
