import 'package:json_annotation/json_annotation.dart';

part 'cancellation_policy_response.g.dart';

@JsonSerializable()
class CancellationPolicyResponse {
  final List<String>? cancellationPolicy;

  CancellationPolicyResponse({
    this.cancellationPolicy,
  });

  factory CancellationPolicyResponse.fromJson(Map<String, dynamic> json) =>
      _$CancellationPolicyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CancellationPolicyResponseToJson(this);
}
