// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DaySetting _$DaySettingFromJson(Map<String, dynamic> json) => DaySetting(
  isAllowFullDay: json['isAllowFullDay'] as bool?,
  time: (json['time'] as List<dynamic>?)
      ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DaySettingToJson(DaySetting instance) =>
    <String, dynamic>{
      'isAllowFullDay': instance.isAllowFullDay,
      'time': instance.time,
    };

TimeSlot _$TimeSlotFromJson(Map<String, dynamic> json) => TimeSlot(
  startTime: (json['startTime'] as num?)?.toInt(),
  endTime: (json['endTime'] as num?)?.toInt(),
);

Map<String, dynamic> _$TimeSlotToJson(TimeSlot instance) => <String, dynamic>{
  'startTime': instance.startTime,
  'endTime': instance.endTime,
};
