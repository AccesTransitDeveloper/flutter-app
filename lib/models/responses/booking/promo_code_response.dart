import 'package:json_annotation/json_annotation.dart';

part 'promo_code_response.g.dart';

@JsonSerializable()
class PromoCodeResponse {
  final List<PromoCodes>? promoCodes;

  PromoCodeResponse({this.promoCodes});

  factory PromoCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$PromoCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PromoCodeResponseToJson(this);
}

@JsonSerializable()
class PromoCodes {
  final String? bannerImageUrl;
  final String? code;
  final String? description;
  final String? imageUrl;
  final bool? isMaxDiscountLimit;
  final int? maxDiscountLimit;
  final int? priceType;
  final String? title;
  final double? value;
  final List<String>? termsAndConditions;

  PromoCodes({
    this.bannerImageUrl,
    this.code,
    this.description,
    this.imageUrl,
    this.isMaxDiscountLimit,
    this.maxDiscountLimit,
    this.priceType,
    this.title,
    this.value,
    this.termsAndConditions,
  });

  factory PromoCodes.fromJson(Map<String, dynamic> json) =>
      _$PromoCodesFromJson(json);

  Map<String, dynamic> toJson() => _$PromoCodesToJson(this);
}

@JsonSerializable()
class ValidatePromoCodeResponse {
  final PromoDetail? promoDetail;

  ValidatePromoCodeResponse({this.promoDetail});

  factory ValidatePromoCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidatePromoCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ValidatePromoCodeResponseToJson(this);
}

@JsonSerializable()
class PromoDetail {
  final double? discount;
  final int? discountType;
  final String? id;
  final String? code;
  final double? promoBonus;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? promoAppliedStr;

  PromoDetail({
    this.discount,
    this.discountType,
    this.id,
    this.code,
    this.promoBonus,
    this.promoAppliedStr,
  });

  factory PromoDetail.fromJson(Map<String, dynamic> json) =>
      _$PromoDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PromoDetailToJson(this);
}
