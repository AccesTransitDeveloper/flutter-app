import 'package:json_annotation/json_annotation.dart';

part 'entity_detail_request.g.dart';

@JsonSerializable()
class EntityDetailRequest {
  final String? countryCode;

  EntityDetailRequest({
    this.countryCode,
  });

  factory EntityDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$EntityDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EntityDetailRequestToJson(this);
}
