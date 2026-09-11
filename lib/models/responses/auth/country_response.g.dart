// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountryResponse _$CountryResponseFromJson(Map<String, dynamic> json) =>
    CountryResponse(
      countries: (json['countries'] as List<dynamic>?)
          ?.map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CountryResponseToJson(CountryResponse instance) =>
    <String, dynamic>{'countries': instance.countries};

Country _$CountryFromJson(Map<String, dynamic> json) => Country(
  id: json['_id'] as String?,
  name: json['name'] as String?,
  phoneCodes: (json['phoneCodes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  currencyCode: json['currencyCode'] as String?,
  currencySign: json['currencySign'] as String?,
  alpha2: json['alpha2'] as String?,
  code: json['code'] as String?,
  code2: json['code2'] as String?,
  timezones: (json['timezones'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isBusiness: json['isBusiness'] as bool?,
  phoneCode: json['phoneCode'] as String?,
);

Map<String, dynamic> _$CountryToJson(Country instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'phoneCodes': instance.phoneCodes,
  'currencyCode': instance.currencyCode,
  'currencySign': instance.currencySign,
  'alpha2': instance.alpha2,
  'code': instance.code,
  'code2': instance.code2,
  'timezones': instance.timezones,
  'isBusiness': instance.isBusiness,
  'phoneCode': instance.phoneCode,
};
