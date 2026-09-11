import 'package:json_annotation/json_annotation.dart';

part 'validate_promo_code_request.g.dart';

@JsonSerializable(includeIfNull: false)
class ValidatePromoCodeRequest {
  final double? latitude;
  final double? longitude;
  final String? promoCode;
  final int? paymentMethod;
  final String? cityId;
  final int? bookingTime;
  final String? vehicleTypeId;
  final int? priceMode;

  ValidatePromoCodeRequest({
    this.latitude,
    this.longitude,
    this.promoCode,
    this.paymentMethod,
    this.cityId,
    this.bookingTime,
    this.vehicleTypeId,
    this.priceMode,
  });

  factory ValidatePromoCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidatePromoCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ValidatePromoCodeRequestToJson(this);
}
