import 'package:json_annotation/json_annotation.dart';

part 'header_response.g.dart';

@JsonSerializable()
class HeaderResponse {
  final String? authorization;
  final String? id;

  HeaderResponse({
    this.authorization,
    this.id,
  });

  factory HeaderResponse.fromJson(Map<String, dynamic> json) =>
      _$HeaderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HeaderResponseToJson(this);
}
