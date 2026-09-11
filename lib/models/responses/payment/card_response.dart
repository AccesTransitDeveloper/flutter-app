import 'package:json_annotation/json_annotation.dart';

part 'card_response.g.dart';

@JsonSerializable()
class GetCardsResponse {
  final List<CardResponse>? cards;

  GetCardsResponse({this.cards});

  factory GetCardsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetCardsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetCardsResponseToJson(this);
}

@JsonSerializable()
class CardResponse {
  final String? cardType;
  final String? fingerprint;
  @JsonKey(name: '_id')
  final String? id;
  final bool? isDefault;
  final String? lastFour;
  final String? paymentCustomerId;
  final int? paymentGatewayType;
  final String? paymentGatewayTypeId;
  final String? token;
  final int? type;
  final String? typeId;
  final String? cardName;
  final bool? isEnable;

  CardResponse({
    this.cardType,
    this.fingerprint,
    this.id,
    this.isDefault,
    this.lastFour,
    this.paymentCustomerId,
    this.paymentGatewayType,
    this.paymentGatewayTypeId,
    this.token,
    this.type,
    this.typeId,
    this.cardName,
    this.isEnable,
  });

  factory CardResponse.fromJson(Map<String, dynamic> json) =>
      _$CardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CardResponseToJson(this);

  CardResponse copyWith({
    String? cardType,
    String? fingerprint,
    String? id,
    bool? isDefault,
    String? lastFour,
    String? paymentCustomerId,
    int? paymentGatewayType,
    String? paymentGatewayTypeId,
    String? token,
    int? type,
    String? typeId,
    String? cardName,
    bool? isEnable,
  }) {
    return CardResponse(
      cardType: cardType ?? this.cardType,
      fingerprint: fingerprint ?? this.fingerprint,
      id: id ?? this.id,
      isDefault: isDefault ?? this.isDefault,
      lastFour: lastFour ?? this.lastFour,
      paymentCustomerId: paymentCustomerId ?? this.paymentCustomerId,
      paymentGatewayType: paymentGatewayType ?? this.paymentGatewayType,
      paymentGatewayTypeId: paymentGatewayTypeId ?? this.paymentGatewayTypeId,
      token: token ?? this.token,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      cardName: cardName ?? this.cardName,
      isEnable: isEnable ?? this.isEnable,
    );
  }
}
