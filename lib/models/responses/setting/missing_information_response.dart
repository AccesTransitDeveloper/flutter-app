import 'package:json_annotation/json_annotation.dart';

part 'missing_information_response.g.dart';

@JsonSerializable()
class MissingInformationResponse {
  final InformationStatus? informationStatus;
  final int? cashBookingMinimumWallet;

  MissingInformationResponse({
    this.informationStatus,
    this.cashBookingMinimumWallet,
  });

  factory MissingInformationResponse.fromJson(Map<String, dynamic> json) =>
      _$MissingInformationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MissingInformationResponseToJson(this);
}

@JsonSerializable()
class InformationStatus {
  final bool cityStatus;
  final bool countryStatus;
  final int documentStatus;
  final bool profileStatus;
  final bool creditStatus;
  final int typeStatus;

  InformationStatus({
    this.cityStatus = false,
    this.countryStatus = false,
    this.documentStatus = 0,
    this.profileStatus = false,
    this.creditStatus = false,
    this.typeStatus = 0,
  });

  factory InformationStatus.fromJson(Map<String, dynamic> json) =>
      _$InformationStatusFromJson(json);

  Map<String, dynamic> toJson() => _$InformationStatusToJson(this);
}
