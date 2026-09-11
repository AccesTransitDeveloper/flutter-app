import 'package:json_annotation/json_annotation.dart';

part 'bidding_accept_request.g.dart';

@JsonSerializable(includeIfNull: false)
class BiddingAcceptRequest {
  final String? bookingId;
  final String? driverId;

  BiddingAcceptRequest({
    this.bookingId,
    this.driverId,
  });

  factory BiddingAcceptRequest.fromJson(Map<String, dynamic> json) =>
      _$BiddingAcceptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BiddingAcceptRequestToJson(this);
}
