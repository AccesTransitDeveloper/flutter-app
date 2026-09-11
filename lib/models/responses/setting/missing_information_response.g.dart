// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_information_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissingInformationResponse _$MissingInformationResponseFromJson(
  Map<String, dynamic> json,
) => MissingInformationResponse(
  informationStatus: json['informationStatus'] == null
      ? null
      : InformationStatus.fromJson(
          json['informationStatus'] as Map<String, dynamic>,
        ),
  cashBookingMinimumWallet: (json['cashBookingMinimumWallet'] as num?)?.toInt(),
);

Map<String, dynamic> _$MissingInformationResponseToJson(
  MissingInformationResponse instance,
) => <String, dynamic>{
  'informationStatus': instance.informationStatus,
  'cashBookingMinimumWallet': instance.cashBookingMinimumWallet,
};

InformationStatus _$InformationStatusFromJson(Map<String, dynamic> json) =>
    InformationStatus(
      cityStatus: json['cityStatus'] as bool? ?? false,
      countryStatus: json['countryStatus'] as bool? ?? false,
      documentStatus: (json['documentStatus'] as num?)?.toInt() ?? 0,
      profileStatus: json['profileStatus'] as bool? ?? false,
      creditStatus: json['creditStatus'] as bool? ?? false,
      typeStatus: (json['typeStatus'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$InformationStatusToJson(InformationStatus instance) =>
    <String, dynamic>{
      'cityStatus': instance.cityStatus,
      'countryStatus': instance.countryStatus,
      'documentStatus': instance.documentStatus,
      'profileStatus': instance.profileStatus,
      'creditStatus': instance.creditStatus,
      'typeStatus': instance.typeStatus,
    };
