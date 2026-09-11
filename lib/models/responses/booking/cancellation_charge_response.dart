import 'package:json_annotation/json_annotation.dart';

part 'cancellation_charge_response.g.dart';

@JsonSerializable()
class CancellationChargeResponse {
  final List<Charge>? charges;
  final List<dynamic>? taxPrices;
  final double? total;
  final double? driverProfit;
  final List<String>? notes;

  CancellationChargeResponse({
    this.charges,
    this.taxPrices,
    this.total,
    this.driverProfit,
    this.notes,
  });

  factory CancellationChargeResponse.fromJson(Map<String, dynamic> json) =>
      _$CancellationChargeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CancellationChargeResponseToJson(this);
}

@JsonSerializable()
class Charge {
  final String? title;
  final double? price;
  final int? type;

  Charge({
    this.title,
    this.price,
    this.type,
  });

  factory Charge.fromJson(Map<String, dynamic> json) => _$ChargeFromJson(json);

  Map<String, dynamic> toJson() => _$ChargeToJson(this);
}
