import 'package:json_annotation/json_annotation.dart';

import 'get_vehicle_types_request.dart';

part 'fare_estimate_request.g.dart';

@JsonSerializable(includeIfNull: false)
class FareEstimateRequest {
  final String? countryCode;
  final String? vehiclePriceId;
  final int? businessType;
  final int? priceMode;
  final DestinationAddress? pickupAddress;
  final List<DestinationAddress>? destinationAddresses;
  final String? promoCodeId;
  final int? bookingTime;
  final int? paymentMode;
  final int? bookingType;
  final String? customerNote;
  final List<String>? accessibilityIds;

  FareEstimateRequest({
    this.countryCode,
    this.vehiclePriceId,
    this.businessType,
    this.priceMode,
    this.pickupAddress,
    this.destinationAddresses,
    this.promoCodeId,
    this.bookingTime,
    this.paymentMode,
    this.bookingType,
    this.customerNote,
    this.accessibilityIds,
  });

  factory FareEstimateRequest.fromJson(Map<String, dynamic> json) =>
      _$FareEstimateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FareEstimateRequestToJson(this);

  FareEstimateRequest copyWith({
    String? countryCode,
    String? vehiclePriceId,
    int? businessType,
    int? priceMode,
    DestinationAddress? pickupAddress,
    List<DestinationAddress>? destinationAddresses,
    String? promoCodeId,
    int? bookingTime,
    int? paymentMode,
    int? bookingType,
    String? customerNote,
    List<String>? accessibilityIds,
  }) {
    return FareEstimateRequest(
      countryCode: countryCode ?? this.countryCode,
      vehiclePriceId: vehiclePriceId ?? this.vehiclePriceId,
      businessType: businessType ?? this.businessType,
      priceMode: priceMode ?? this.priceMode,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddresses: destinationAddresses ?? this.destinationAddresses,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      bookingTime: bookingTime ?? this.bookingTime,
      paymentMode: paymentMode ?? this.paymentMode,
      bookingType: bookingType ?? this.bookingType,
      customerNote: customerNote ?? this.customerNote,
      accessibilityIds: accessibilityIds ?? this.accessibilityIds,
    );
  }
}
