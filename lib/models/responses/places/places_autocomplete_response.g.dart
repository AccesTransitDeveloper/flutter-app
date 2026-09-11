// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_autocomplete_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlacesAutocompleteResponse _$PlacesAutocompleteResponseFromJson(
  Map<String, dynamic> json,
) => PlacesAutocompleteResponse(
  predictions: (json['predictions'] as List<dynamic>?)
      ?.map((e) => AutocompletePrediction.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String?,
  errorMessage: json['error_message'] as String?,
);

Map<String, dynamic> _$PlacesAutocompleteResponseToJson(
  PlacesAutocompleteResponse instance,
) => <String, dynamic>{
  'predictions': instance.predictions,
  'status': instance.status,
  'error_message': instance.errorMessage,
};

AutocompletePrediction _$AutocompletePredictionFromJson(
  Map<String, dynamic> json,
) => AutocompletePrediction(
  description: json['description'] as String?,
  placeId: json['place_id'] as String?,
  reference: json['reference'] as String?,
  structuredFormatting: json['structured_formatting'] == null
      ? null
      : StructuredFormatting.fromJson(
          json['structured_formatting'] as Map<String, dynamic>,
        ),
  terms: (json['terms'] as List<dynamic>?)
      ?.map((e) => Term.fromJson(e as Map<String, dynamic>))
      .toList(),
  types: (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$AutocompletePredictionToJson(
  AutocompletePrediction instance,
) => <String, dynamic>{
  'description': instance.description,
  'place_id': instance.placeId,
  'reference': instance.reference,
  'structured_formatting': instance.structuredFormatting,
  'terms': instance.terms,
  'types': instance.types,
};

StructuredFormatting _$StructuredFormattingFromJson(
  Map<String, dynamic> json,
) => StructuredFormatting(
  mainText: json['main_text'] as String?,
  secondaryText: json['secondary_text'] as String?,
);

Map<String, dynamic> _$StructuredFormattingToJson(
  StructuredFormatting instance,
) => <String, dynamic>{
  'main_text': instance.mainText,
  'secondary_text': instance.secondaryText,
};

Term _$TermFromJson(Map<String, dynamic> json) => Term(
  offset: (json['offset'] as num?)?.toInt(),
  value: json['value'] as String?,
);

Map<String, dynamic> _$TermToJson(Term instance) => <String, dynamic>{
  'offset': instance.offset,
  'value': instance.value,
};
