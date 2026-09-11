// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geocode_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeocodeResponse _$GeocodeResponseFromJson(Map<String, dynamic> json) =>
    GeocodeResponse(
      plusCode: json['plus_code'] == null
          ? null
          : PlusCode.fromJson(json['plus_code'] as Map<String, dynamic>),
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => GeocodeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      routes: (json['routes'] as List<dynamic>?)
          ?.map((e) => GeocodeRoutes.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      predictions: (json['predictions'] as List<dynamic>?)
          ?.map((e) => Prediction.fromJson(e as Map<String, dynamic>))
          .toList(),
      destinationAddresses: (json['destination_addresses'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList(),
      originAddresses: (json['origin_addresses'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList(),
      rows: (json['rows'] as List<dynamic>?)
          ?.map(
            (e) => e == null ? null : Row.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$GeocodeResponseToJson(GeocodeResponse instance) =>
    <String, dynamic>{
      'plus_code': instance.plusCode,
      'results': instance.results,
      'routes': instance.routes,
      'status': instance.status,
      'predictions': instance.predictions,
      'destination_addresses': instance.destinationAddresses,
      'origin_addresses': instance.originAddresses,
      'rows': instance.rows,
    };

Row _$RowFromJson(Map<String, dynamic> json) => Row(
  elements: (json['elements'] as List<dynamic>?)
      ?.map(
        (e) => e == null ? null : Element.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$RowToJson(Row instance) => <String, dynamic>{
  'elements': instance.elements,
};

Element _$ElementFromJson(Map<String, dynamic> json) => Element(
  distance: json['distance'] == null
      ? null
      : Distance.fromJson(json['distance'] as Map<String, dynamic>),
  duration: json['duration'] == null
      ? null
      : Duration.fromJson(json['duration'] as Map<String, dynamic>),
  status: json['status'] as String?,
);

Map<String, dynamic> _$ElementToJson(Element instance) => <String, dynamic>{
  'distance': instance.distance,
  'duration': instance.duration,
  'status': instance.status,
};

Prediction _$PredictionFromJson(Map<String, dynamic> json) => Prediction(
  description: json['description'] as String?,
  matchedSubstrings: (json['matched_substrings'] as List<dynamic>?)
      ?.map(
        (e) => e == null
            ? null
            : MatchedSubstring.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  placeId: json['place_id'] as String?,
  reference: json['reference'] as String?,
  structuredFormatting: json['structured_formatting'] == null
      ? null
      : StructuredFormatting.fromJson(
          json['structured_formatting'] as Map<String, dynamic>,
        ),
  terms: (json['terms'] as List<dynamic>?)
      ?.map((e) => e == null ? null : Term.fromJson(e as Map<String, dynamic>))
      .toList(),
  types: (json['types'] as List<dynamic>?)?.map((e) => e as String?).toList(),
);

Map<String, dynamic> _$PredictionToJson(Prediction instance) =>
    <String, dynamic>{
      'description': instance.description,
      'matched_substrings': instance.matchedSubstrings,
      'place_id': instance.placeId,
      'reference': instance.reference,
      'structured_formatting': instance.structuredFormatting,
      'terms': instance.terms,
      'types': instance.types,
    };

MatchedSubstring _$MatchedSubstringFromJson(Map<String, dynamic> json) =>
    MatchedSubstring(
      length: (json['length'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MatchedSubstringToJson(MatchedSubstring instance) =>
    <String, dynamic>{'length': instance.length, 'offset': instance.offset};

StructuredFormatting _$StructuredFormattingFromJson(
  Map<String, dynamic> json,
) => StructuredFormatting(
  mainText: json['main_text'] as String?,
  mainTextMatchedSubstrings:
      (json['main_text_matched_substrings'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : MainTextMatchedSubstring.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  secondaryText: json['secondary_text'] as String?,
);

Map<String, dynamic> _$StructuredFormattingToJson(
  StructuredFormatting instance,
) => <String, dynamic>{
  'main_text': instance.mainText,
  'main_text_matched_substrings': instance.mainTextMatchedSubstrings,
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

MainTextMatchedSubstring _$MainTextMatchedSubstringFromJson(
  Map<String, dynamic> json,
) => MainTextMatchedSubstring(
  length: (json['length'] as num?)?.toInt(),
  offset: (json['offset'] as num?)?.toInt(),
);

Map<String, dynamic> _$MainTextMatchedSubstringToJson(
  MainTextMatchedSubstring instance,
) => <String, dynamic>{'length': instance.length, 'offset': instance.offset};

GeocodeData _$GeocodeDataFromJson(Map<String, dynamic> json) => GeocodeData(
  addressComponents: (json['address_components'] as List<dynamic>?)
      ?.map((e) => AddressComponent.fromJson(e as Map<String, dynamic>))
      .toList(),
  formattedAddress: json['formatted_address'] as String?,
  placeId: json['place_id'] as String?,
  types: (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
  geometry: json['geometry'] == null
      ? null
      : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GeocodeDataToJson(GeocodeData instance) =>
    <String, dynamic>{
      'address_components': instance.addressComponents,
      'formatted_address': instance.formattedAddress,
      'place_id': instance.placeId,
      'types': instance.types,
      'geometry': instance.geometry,
    };

Geometry _$GeometryFromJson(Map<String, dynamic> json) => Geometry(
  location: json['location'] == null
      ? null
      : GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GeometryToJson(Geometry instance) => <String, dynamic>{
  'location': instance.location,
};

GeoLocation _$GeoLocationFromJson(Map<String, dynamic> json) => GeoLocation(
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$GeoLocationToJson(GeoLocation instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

AddressComponent _$AddressComponentFromJson(Map<String, dynamic> json) =>
    AddressComponent(
      longName: json['long_name'] as String?,
      shortName: json['short_name'] as String?,
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AddressComponentToJson(AddressComponent instance) =>
    <String, dynamic>{
      'long_name': instance.longName,
      'short_name': instance.shortName,
      'types': instance.types,
    };

PlusCode _$PlusCodeFromJson(Map<String, dynamic> json) => PlusCode(
  compoundCode: json['compound_code'] as String?,
  globalCode: json['global_code'] as String?,
);

Map<String, dynamic> _$PlusCodeToJson(PlusCode instance) => <String, dynamic>{
  'compound_code': instance.compoundCode,
  'global_code': instance.globalCode,
};

GeocodeRoutes _$GeocodeRoutesFromJson(Map<String, dynamic> json) =>
    GeocodeRoutes(
      bounds: json['bounds'] == null
          ? null
          : Bounds.fromJson(json['bounds'] as Map<String, dynamic>),
      copyrights: json['copyrights'] as String?,
      legs: (json['legs'] as List<dynamic>?)
          ?.map((e) => Leg.fromJson(e as Map<String, dynamic>))
          .toList(),
      overviewPolyline: json['overview_polyline'] == null
          ? null
          : OverviewPolyline.fromJson(
              json['overview_polyline'] as Map<String, dynamic>,
            ),
      summary: json['summary'] as String?,
      warnings: json['warnings'] as List<dynamic>?,
      waypointOrder: json['waypoint_order'] as List<dynamic>?,
    );

Map<String, dynamic> _$GeocodeRoutesToJson(GeocodeRoutes instance) =>
    <String, dynamic>{
      'bounds': instance.bounds,
      'copyrights': instance.copyrights,
      'legs': instance.legs,
      'overview_polyline': instance.overviewPolyline,
      'summary': instance.summary,
      'warnings': instance.warnings,
      'waypoint_order': instance.waypointOrder,
    };

Bounds _$BoundsFromJson(Map<String, dynamic> json) => Bounds(
  northeast: json['northeast'] == null
      ? null
      : Northeast.fromJson(json['northeast'] as Map<String, dynamic>),
  southwest: json['southwest'] == null
      ? null
      : Southwest.fromJson(json['southwest'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BoundsToJson(Bounds instance) => <String, dynamic>{
  'northeast': instance.northeast,
  'southwest': instance.southwest,
};

Leg _$LegFromJson(Map<String, dynamic> json) => Leg(
  distance: json['distance'] == null
      ? null
      : Distance.fromJson(json['distance'] as Map<String, dynamic>),
  duration: json['duration'] == null
      ? null
      : Duration.fromJson(json['duration'] as Map<String, dynamic>),
  durationInTraffic: json['duration_in_traffic'] == null
      ? null
      : Duration.fromJson(json['duration_in_traffic'] as Map<String, dynamic>),
  endAddress: json['end_address'] as String?,
  endLocation: json['end_location'] == null
      ? null
      : EndLocation.fromJson(json['end_location'] as Map<String, dynamic>),
  startAddress: json['start_address'] as String?,
  startLocation: json['start_location'] == null
      ? null
      : StartLocation.fromJson(json['start_location'] as Map<String, dynamic>),
  steps: (json['steps'] as List<dynamic>?)
      ?.map((e) => Step.fromJson(e as Map<String, dynamic>))
      .toList(),
  trafficSpeedEntry: json['traffic_speed_entry'] as List<dynamic>?,
  viaWaypoint: json['via_waypoint'] as List<dynamic>?,
);

Map<String, dynamic> _$LegToJson(Leg instance) => <String, dynamic>{
  'distance': instance.distance,
  'duration': instance.duration,
  'duration_in_traffic': instance.durationInTraffic,
  'end_address': instance.endAddress,
  'end_location': instance.endLocation,
  'start_address': instance.startAddress,
  'start_location': instance.startLocation,
  'steps': instance.steps,
  'traffic_speed_entry': instance.trafficSpeedEntry,
  'via_waypoint': instance.viaWaypoint,
};

OverviewPolyline _$OverviewPolylineFromJson(Map<String, dynamic> json) =>
    OverviewPolyline(points: json['points'] as String?);

Map<String, dynamic> _$OverviewPolylineToJson(OverviewPolyline instance) =>
    <String, dynamic>{'points': instance.points};

Northeast _$NortheastFromJson(Map<String, dynamic> json) => Northeast(
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$NortheastToJson(Northeast instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

Southwest _$SouthwestFromJson(Map<String, dynamic> json) => Southwest(
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$SouthwestToJson(Southwest instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

Distance _$DistanceFromJson(Map<String, dynamic> json) => Distance(
  text: json['text'] as String?,
  value: (json['value'] as num?)?.toInt(),
);

Map<String, dynamic> _$DistanceToJson(Distance instance) => <String, dynamic>{
  'text': instance.text,
  'value': instance.value,
};

Duration _$DurationFromJson(Map<String, dynamic> json) => Duration(
  text: json['text'] as String?,
  value: (json['value'] as num?)?.toInt(),
);

Map<String, dynamic> _$DurationToJson(Duration instance) => <String, dynamic>{
  'text': instance.text,
  'value': instance.value,
};

EndLocation _$EndLocationFromJson(Map<String, dynamic> json) => EndLocation(
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$EndLocationToJson(EndLocation instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

StartLocation _$StartLocationFromJson(Map<String, dynamic> json) =>
    StartLocation(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StartLocationToJson(StartLocation instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

Step _$StepFromJson(Map<String, dynamic> json) => Step(
  distance: json['distance'] == null
      ? null
      : Distance.fromJson(json['distance'] as Map<String, dynamic>),
  duration: json['duration'] == null
      ? null
      : Duration.fromJson(json['duration'] as Map<String, dynamic>),
  endLocation: json['end_location'] == null
      ? null
      : EndLocation.fromJson(json['end_location'] as Map<String, dynamic>),
  htmlInstructions: json['html_instructions'] as String?,
  polyline: json['polyline'] == null
      ? null
      : Polyline.fromJson(json['polyline'] as Map<String, dynamic>),
  startLocation: json['start_location'] == null
      ? null
      : StartLocation.fromJson(json['start_location'] as Map<String, dynamic>),
  travelMode: json['travel_mode'] as String?,
);

Map<String, dynamic> _$StepToJson(Step instance) => <String, dynamic>{
  'distance': instance.distance,
  'duration': instance.duration,
  'end_location': instance.endLocation,
  'html_instructions': instance.htmlInstructions,
  'polyline': instance.polyline,
  'start_location': instance.startLocation,
  'travel_mode': instance.travelMode,
};

Polyline _$PolylineFromJson(Map<String, dynamic> json) =>
    Polyline(points: json['points'] as String?);

Map<String, dynamic> _$PolylineToJson(Polyline instance) => <String, dynamic>{
  'points': instance.points,
};
