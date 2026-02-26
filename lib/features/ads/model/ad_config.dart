import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad_config.freezed.dart';
part 'ad_config.g.dart';

@freezed
class AdConfig with _$AdConfig {
  const factory AdConfig({
    @JsonKey(name: 'config_version') required String configVersion,
    required Ads ads,
  }) = _AdConfig;

  factory AdConfig.fromJson(Map<String, dynamic> json) => _$AdConfigFromJson(json);
}

@freezed
class Ads with _$Ads {
  const factory Ads({
    @JsonKey(name: 'home_banner_top') required AdItem homeBannerTop,
    @JsonKey(name: 'home_banner_bottom') required AdItem homeBannerBottom,
    @JsonKey(name: 'reward_ad') required AdItem rewardAd,
  }) = _Ads;

  factory Ads.fromJson(Map<String, dynamic> json) => _$AdsFromJson(json);
}

@freezed
class AdItem with _$AdItem {
  const factory AdItem({
    @JsonKey(name: 'is_enabled') required bool isEnabled,
    required String type,
    @JsonKey(name: 'media_source') required String mediaSource,
    @JsonKey(name: 'target_url') String? targetUrl,
    @JsonKey(name: 'height_factor') double? heightFactor,
    @JsonKey(name: 'timer_seconds') int? timerSeconds,
    @JsonKey(name: 'can_skip') bool? canSkip,
  }) = _AdItem;

  factory AdItem.fromJson(Map<String, dynamic> json) => _$AdItemFromJson(json);
}
