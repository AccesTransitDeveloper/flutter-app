// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_business_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckBusinessResponse _$CheckBusinessResponseFromJson(
  Map<String, dynamic> json,
) => CheckBusinessResponse(
  countryId: json['countryId'] as String?,
  cityId: json['cityId'] as String?,
  isAds: json['isAds'] as bool? ?? false,
  businessTypeSettings: (json['businessTypeSettings'] as List<dynamic>?)
      ?.map((e) => BusinessTypeSetting.fromJson(e as Map<String, dynamic>))
      .toList(),
  businessTypes: (json['businessTypes'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$CheckBusinessResponseToJson(
  CheckBusinessResponse instance,
) => <String, dynamic>{
  'countryId': instance.countryId,
  'cityId': instance.cityId,
  'isAds': instance.isAds,
  'businessTypeSettings': instance.businessTypeSettings,
  'businessTypes': instance.businessTypes,
};

BusinessTypeSetting _$BusinessTypeSettingFromJson(Map<String, dynamic> json) =>
    BusinessTypeSetting(
      businessType: (json['businessType'] as num?)?.toInt(),
      businessTypeLogo: json['businessTypeLogo'] as String?,
      darkBusinessTypeLogo: json['darkBusinessTypeLogo'] as String?,
      businessTypeBackground: json['businessTypeBackground'] as String?,
      darkBusinessTypeBackground: json['darkBusinessTypeBackground'] as String?,
    );

Map<String, dynamic> _$BusinessTypeSettingToJson(
  BusinessTypeSetting instance,
) => <String, dynamic>{
  'businessType': instance.businessType,
  'businessTypeLogo': instance.businessTypeLogo,
  'darkBusinessTypeLogo': instance.darkBusinessTypeLogo,
  'businessTypeBackground': instance.businessTypeBackground,
  'darkBusinessTypeBackground': instance.darkBusinessTypeBackground,
};
