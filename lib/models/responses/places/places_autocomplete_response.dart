import 'package:json_annotation/json_annotation.dart';

part 'places_autocomplete_response.g.dart';

@JsonSerializable()
class PlacesAutocompleteResponse {
  final List<AutocompletePrediction>? predictions;
  final String? status;
  @JsonKey(name: 'error_message')
  final String? errorMessage;

  PlacesAutocompleteResponse({
    this.predictions,
    this.status,
    this.errorMessage,
  });

  factory PlacesAutocompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$PlacesAutocompleteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlacesAutocompleteResponseToJson(this);
}

@JsonSerializable()
class AutocompletePrediction {
  final String? description;
  @JsonKey(name: 'place_id')
  final String? placeId;
  final String? reference;
  @JsonKey(name: 'structured_formatting')
  final StructuredFormatting? structuredFormatting;
  final List<Term>? terms;
  final List<String>? types;

  AutocompletePrediction({
    this.description,
    this.placeId,
    this.reference,
    this.structuredFormatting,
    this.terms,
    this.types,
  });

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) =>
      _$AutocompletePredictionFromJson(json);

  Map<String, dynamic> toJson() => _$AutocompletePredictionToJson(this);
}

@JsonSerializable()
class StructuredFormatting {
  @JsonKey(name: 'main_text')
  final String? mainText;
  @JsonKey(name: 'secondary_text')
  final String? secondaryText;

  StructuredFormatting({
    this.mainText,
    this.secondaryText,
  });

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) =>
      _$StructuredFormattingFromJson(json);

  Map<String, dynamic> toJson() => _$StructuredFormattingToJson(this);
}

@JsonSerializable()
class Term {
  final int? offset;
  final String? value;

  Term({
    this.offset,
    this.value,
  });

  factory Term.fromJson(Map<String, dynamic> json) => _$TermFromJson(json);

  Map<String, dynamic> toJson() => _$TermToJson(this);
}
