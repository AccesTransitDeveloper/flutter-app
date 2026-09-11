// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_code_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoCodeResponse _$PromoCodeResponseFromJson(Map<String, dynamic> json) =>
    PromoCodeResponse(
      promoCodes: (json['promoCodes'] as List<dynamic>?)
          ?.map((e) => PromoCodes.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PromoCodeResponseToJson(PromoCodeResponse instance) =>
    <String, dynamic>{'promoCodes': instance.promoCodes};

PromoCodes _$PromoCodesFromJson(Map<String, dynamic> json) => PromoCodes(
  bannerImageUrl: json['bannerImageUrl'] as String?,
  code: json['code'] as String?,
  description: json['description'] as String?,
  imageUrl: json['imageUrl'] as String?,
  isMaxDiscountLimit: json['isMaxDiscountLimit'] as bool?,
  maxDiscountLimit: (json['maxDiscountLimit'] as num?)?.toInt(),
  priceType: (json['priceType'] as num?)?.toInt(),
  title: json['title'] as String?,
  value: (json['value'] as num?)?.toDouble(),
  termsAndConditions: (json['termsAndConditions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$PromoCodesToJson(PromoCodes instance) =>
    <String, dynamic>{
      'bannerImageUrl': instance.bannerImageUrl,
      'code': instance.code,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'isMaxDiscountLimit': instance.isMaxDiscountLimit,
      'maxDiscountLimit': instance.maxDiscountLimit,
      'priceType': instance.priceType,
      'title': instance.title,
      'value': instance.value,
      'termsAndConditions': instance.termsAndConditions,
    };

ValidatePromoCodeResponse _$ValidatePromoCodeResponseFromJson(
  Map<String, dynamic> json,
) => ValidatePromoCodeResponse(
  promoDetail: json['promoDetail'] == null
      ? null
      : PromoDetail.fromJson(json['promoDetail'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ValidatePromoCodeResponseToJson(
  ValidatePromoCodeResponse instance,
) => <String, dynamic>{'promoDetail': instance.promoDetail};

PromoDetail _$PromoDetailFromJson(Map<String, dynamic> json) => PromoDetail(
  discount: (json['discount'] as num?)?.toDouble(),
  discountType: (json['discountType'] as num?)?.toInt(),
  id: json['id'] as String?,
  code: json['code'] as String?,
  promoBonus: (json['promoBonus'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PromoDetailToJson(PromoDetail instance) =>
    <String, dynamic>{
      'discount': instance.discount,
      'discountType': instance.discountType,
      'id': instance.id,
      'code': instance.code,
      'promoBonus': instance.promoBonus,
    };
