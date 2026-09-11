import 'package:json_annotation/json_annotation.dart';

part 'string_object.g.dart';

@JsonSerializable()
class StringObject {
  @JsonKey(name: 'COMMON')
  final String? common;
  @JsonKey(name: 'TAXI')
  final String? taxi;
  @JsonKey(name: 'QUICK_COMMERCE')
  final String? quickCommerce;
  @JsonKey(name: 'DELIVERY')
  final String? delivery;
  @JsonKey(name: 'SERVICE')
  final String? service;
  @JsonKey(name: 'COURIER')
  final String? courier;

  StringObject({
    this.common,
    this.taxi,
    this.quickCommerce,
    this.delivery,
    this.service,
    this.courier,
  });

  factory StringObject.fromJson(Map<String, dynamic> json) =>
      _$StringObjectFromJson(json);

  Map<String, dynamic> toJson() => _$StringObjectToJson(this);
}
