// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_type_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessTypeRequest _$BusinessTypeRequestFromJson(Map<String, dynamic> json) =>
    BusinessTypeRequest(
      address: json['address'] == null
          ? null
          : CheckBusinessAddress.fromJson(
              json['address'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BusinessTypeRequestToJson(
  BusinessTypeRequest instance,
) => <String, dynamic>{'address': instance.address};

CheckBusinessAddress _$CheckBusinessAddressFromJson(
  Map<String, dynamic> json,
) => CheckBusinessAddress(
  countryCode: json['countryCode'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CheckBusinessAddressToJson(
  CheckBusinessAddress instance,
) => <String, dynamic>{
  'countryCode': instance.countryCode,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
