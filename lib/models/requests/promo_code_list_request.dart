import 'package:json_annotation/json_annotation.dart';

part 'promo_code_list_request.g.dart';

@JsonSerializable(includeIfNull: false)
class PromoCodeListRequest {
  final String? cityId;
  final String? countryId;
  final String? vehicleTypeId;
  final int? priceMode;
  final int? businessType;

  PromoCodeListRequest({
    this.cityId,
    this.countryId,
    this.vehicleTypeId,
    this.priceMode,
    this.businessType,
  });

  factory PromoCodeListRequest.fromJson(Map<String, dynamic> json) =>
      _$PromoCodeListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PromoCodeListRequestToJson(this);
}
