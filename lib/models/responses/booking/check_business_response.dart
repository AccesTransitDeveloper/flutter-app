import 'package:json_annotation/json_annotation.dart';

part 'check_business_response.g.dart';

@JsonSerializable()
class CheckBusinessResponse {
  final String? countryId;
  final String? cityId;
  final bool isAds;
  final List<BusinessTypeSetting>? businessTypeSettings;
  final List<int>? businessTypes;

  CheckBusinessResponse({
    this.countryId,
    this.cityId,
    this.isAds = false,
    this.businessTypeSettings,
    this.businessTypes,
  });

  factory CheckBusinessResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckBusinessResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckBusinessResponseToJson(this);
}

@JsonSerializable()
class BusinessTypeSetting {
  final int? businessType;
  final String? businessTypeLogo;
  final String? darkBusinessTypeLogo;
  final String? businessTypeBackground;
  final String? darkBusinessTypeBackground;

  BusinessTypeSetting({
    this.businessType,
    this.businessTypeLogo,
    this.darkBusinessTypeLogo,
    this.businessTypeBackground,
    this.darkBusinessTypeBackground,
  });

  factory BusinessTypeSetting.fromJson(Map<String, dynamic> json) =>
      _$BusinessTypeSettingFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessTypeSettingToJson(this);
}
