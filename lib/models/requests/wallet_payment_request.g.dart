// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletPaymentRequest _$WalletPaymentRequestFromJson(
  Map<String, dynamic> json,
) => WalletPaymentRequest(
  amount: (json['amount'] as num?)?.toDouble(),
  countryId: json['countryId'] as String?,
  currency: json['currency'] as String?,
  paymentPurpose: (json['paymentPurpose'] as num?)?.toInt(),
  bookingId: json['bookingId'] as String?,
  fixedGroupRideId: json['fixedGroupRideId'] as String?,
  requestData: json['requestData'] == null
      ? null
      : FixGroupRequestData.fromJson(
          json['requestData'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$WalletPaymentRequestToJson(
  WalletPaymentRequest instance,
) => <String, dynamic>{
  'amount': ?instance.amount,
  'countryId': ?instance.countryId,
  'currency': ?instance.currency,
  'paymentPurpose': ?instance.paymentPurpose,
  'bookingId': ?instance.bookingId,
  'fixedGroupRideId': ?instance.fixedGroupRideId,
  'requestData': ?instance.requestData,
};

FixGroupRequestData _$FixGroupRequestDataFromJson(Map<String, dynamic> json) =>
    FixGroupRequestData(
      priceTypePreference: json['priceTypePreference'] as String?,
    );

Map<String, dynamic> _$FixGroupRequestDataToJson(
  FixGroupRequestData instance,
) => <String, dynamic>{'priceTypePreference': ?instance.priceTypePreference};
