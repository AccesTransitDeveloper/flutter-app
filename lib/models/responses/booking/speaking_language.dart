import 'package:json_annotation/json_annotation.dart';

part 'speaking_language.g.dart';

@JsonSerializable()
class SpeakingLanguage {
  final String? code;
  final String? name;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isSelected;

  SpeakingLanguage({
    this.code,
    this.name,
    this.isSelected = false,
  });

  factory SpeakingLanguage.fromJson(Map<String, dynamic> json) =>
      _$SpeakingLanguageFromJson(json);

  Map<String, dynamic> toJson() => _$SpeakingLanguageToJson(this);

  SpeakingLanguage copyWith({
    String? code,
    String? name,
    bool? isSelected,
  }) {
    return SpeakingLanguage(
      code: code ?? this.code,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
