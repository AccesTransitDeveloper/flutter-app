import 'package:json_annotation/json_annotation.dart';

part 'wallet_payment_request.g.dart';

@JsonSerializable(includeIfNull: false)
class WalletPaymentRequest {
  final double? amount;
  final String? countryId;
  final String? currency;
  final int? paymentPurpose;
  final String? bookingId;
  final String? fixedGroupRideId;
  final FixGroupRequestData? requestData;

  WalletPaymentRequest({
    this.amount,
    this.countryId,
    this.currency,
    this.paymentPurpose,
    this.bookingId,
    this.fixedGroupRideId,
    this.requestData,
  });

  factory WalletPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$WalletPaymentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WalletPaymentRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class FixGroupRequestData {
  final String? priceTypePreference;

  FixGroupRequestData({this.priceTypePreference});

  factory FixGroupRequestData.fromJson(Map<String, dynamic> json) =>
      _$FixGroupRequestDataFromJson(json);

  Map<String, dynamic> toJson() => _$FixGroupRequestDataToJson(this);
}
