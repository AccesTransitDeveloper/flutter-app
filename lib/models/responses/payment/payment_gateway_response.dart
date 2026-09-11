import 'package:json_annotation/json_annotation.dart';

part 'payment_gateway_response.g.dart';

@JsonSerializable()
class PaymentGatewayResponse {
  final List<PaymentGateway>? paymentGateways;

  PaymentGatewayResponse({this.paymentGateways});

  factory PaymentGatewayResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentGatewayResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentGatewayResponseToJson(this);
}

@JsonSerializable()
class PaymentGateway {
  final Credential? credential;
  final bool? isAllowCaptureLater;
  final bool? isAllowSaveBank;
  final bool? isAllowSaveCard;
  final int? type;
  final String? name;

  PaymentGateway({
    this.credential,
    this.isAllowCaptureLater,
    this.isAllowSaveBank,
    this.isAllowSaveCard,
    this.type,
    this.name,
  });

  factory PaymentGateway.fromJson(Map<String, dynamic> json) =>
      _$PaymentGatewayFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentGatewayToJson(this);

  PaymentGateway copyWith({
    Credential? credential,
    bool? isAllowCaptureLater,
    bool? isAllowSaveBank,
    bool? isAllowSaveCard,
    int? type,
    String? name,
  }) {
    return PaymentGateway(
      credential: credential ?? this.credential,
      isAllowCaptureLater: isAllowCaptureLater ?? this.isAllowCaptureLater,
      isAllowSaveBank: isAllowSaveBank ?? this.isAllowSaveBank,
      isAllowSaveCard: isAllowSaveCard ?? this.isAllowSaveCard,
      type: type ?? this.type,
      name: name ?? this.name,
    );
  }
}

@JsonSerializable()
class Credential {
  final String? publicKey;

  Credential({this.publicKey});

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialToJson(this);
}
