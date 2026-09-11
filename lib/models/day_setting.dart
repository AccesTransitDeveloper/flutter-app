import 'package:json_annotation/json_annotation.dart';

part 'day_setting.g.dart';

@JsonSerializable()
class DaySetting {
  @JsonKey(name: 'isAllowFullDay')
  final bool? isAllowFullDay;

  @JsonKey(name: 'time')
  final List<TimeSlot>? time;

  DaySetting({
    this.isAllowFullDay,
    this.time,
  });

  factory DaySetting.fromJson(Map<String, dynamic> json) =>
      _$DaySettingFromJson(json);

  Map<String, dynamic> toJson() => _$DaySettingToJson(this);
}

@JsonSerializable()
class TimeSlot {
  @JsonKey(name: 'startTime')
  final int? startTime;

  @JsonKey(name: 'endTime')
  final int? endTime;

  TimeSlot({
    this.startTime,
    this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);
}
