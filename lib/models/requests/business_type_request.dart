import 'package:json_annotation/json_annotation.dart';

part 'business_type_request.g.dart';

@JsonSerializable()
class BusinessTypeRequest {
  final CheckBusinessAddress? address;

  BusinessTypeRequest({this.address});

  factory BusinessTypeRequest.fromJson(Map<String, dynamic> json) =>
      _$BusinessTypeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessTypeRequestToJson(this);
}

@JsonSerializable()
class CheckBusinessAddress {
  final String? countryCode;
  final double? latitude;
  final double? longitude;

  CheckBusinessAddress({
    this.countryCode,
    this.latitude,
    this.longitude,
  });

  factory CheckBusinessAddress.fromJson(Map<String, dynamic> json) =>
      _$CheckBusinessAddressFromJson(json);

  Map<String, dynamic> toJson() => _$CheckBusinessAddressToJson(this);
}
