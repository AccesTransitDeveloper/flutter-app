import 'package:json_annotation/json_annotation.dart';

part 'error_response.g.dart';

@JsonSerializable()
class ErrorResponse {
  final String? message;

  ErrorResponse({
    this.message,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  String toString() => message ?? 'Unknown error';
}
