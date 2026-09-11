// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'header_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HeaderResponse _$HeaderResponseFromJson(Map<String, dynamic> json) =>
    HeaderResponse(
      authorization: json['authorization'] as String?,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$HeaderResponseToJson(HeaderResponse instance) =>
    <String, dynamic>{
      'authorization': instance.authorization,
      'id': instance.id,
    };
