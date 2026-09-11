// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_policy_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancellationPolicyResponse _$CancellationPolicyResponseFromJson(
  Map<String, dynamic> json,
) => CancellationPolicyResponse(
  cancellationPolicy: (json['cancellationPolicy'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CancellationPolicyResponseToJson(
  CancellationPolicyResponse instance,
) => <String, dynamic>{'cancellationPolicy': instance.cancellationPolicy};
