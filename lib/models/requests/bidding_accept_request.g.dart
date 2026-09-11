// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bidding_accept_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BiddingAcceptRequest _$BiddingAcceptRequestFromJson(
  Map<String, dynamic> json,
) => BiddingAcceptRequest(
  bookingId: json['bookingId'] as String?,
  driverId: json['driverId'] as String?,
);

Map<String, dynamic> _$BiddingAcceptRequestToJson(
  BiddingAcceptRequest instance,
) => <String, dynamic>{
  'bookingId': ?instance.bookingId,
  'driverId': ?instance.driverId,
};
