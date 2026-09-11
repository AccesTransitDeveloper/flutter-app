import 'package:json_annotation/json_annotation.dart';

import 'booking_detail_response.dart';

part 'fare_estimate_response.g.dart';

@JsonSerializable()
class FareEstimateResponse {
  final InvoiceDetail? priceDetail;
  final List<DeliveryOption>? deliveryOptions;
  final List<ItemModifier>? modifiers;

  FareEstimateResponse({
    this.priceDetail,
    this.deliveryOptions,
    this.modifiers,
  });

  factory FareEstimateResponse.fromJson(Map<String, dynamic> json) =>
      _$FareEstimateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FareEstimateResponseToJson(this);
}

@JsonSerializable()
class DeliveryOption {
  @JsonKey(name: '_id')
  final String? id;
  final double? price;
  final String? deliveryOption;
  final int? cutOffTime;
  final int? noOfDay;
  final int? estimatedDeliveryTime;

  DeliveryOption({
    this.id,
    this.price,
    this.deliveryOption,
    this.cutOffTime,
    this.noOfDay,
    this.estimatedDeliveryTime,
  });

  factory DeliveryOption.fromJson(Map<String, dynamic> json) =>
      _$DeliveryOptionFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryOptionToJson(this);
}

@JsonSerializable()
class ItemModifier {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final double? price;

  ItemModifier({
    this.id,
    this.name,
    this.price,
  });

  factory ItemModifier.fromJson(Map<String, dynamic> json) =>
      _$ItemModifierFromJson(json);

  Map<String, dynamic> toJson() => _$ItemModifierToJson(this);
}
