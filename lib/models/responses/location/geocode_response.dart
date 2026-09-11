import 'package:json_annotation/json_annotation.dart';

part 'geocode_response.g.dart';

@JsonSerializable()
class GeocodeResponse {
  @JsonKey(name: 'plus_code')
  final PlusCode? plusCode;

  @JsonKey(name: 'results')
  final List<GeocodeData>? results;

  @JsonKey(name: 'routes')
  final List<GeocodeRoutes>? routes;

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'predictions')
  final List<Prediction>? predictions;

  @JsonKey(name: 'destination_addresses')
  final List<String?>? destinationAddresses;

  @JsonKey(name: 'origin_addresses')
  final List<String?>? originAddresses;

  @JsonKey(name: 'rows')
  final List<Row?>? rows;

  GeocodeResponse({
    this.plusCode,
    this.results,
    this.routes,
    this.status,
    this.predictions,
    this.destinationAddresses,
    this.originAddresses,
    this.rows,
  });

  factory GeocodeResponse.fromJson(Map<String, dynamic> json) =>
      _$GeocodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GeocodeResponseToJson(this);
}

@JsonSerializable()
class Row {
  @JsonKey(name: 'elements')
  final List<Element?>? elements;

  Row({this.elements});

  factory Row.fromJson(Map<String, dynamic> json) => _$RowFromJson(json);

  Map<String, dynamic> toJson() => _$RowToJson(this);
}

@JsonSerializable()
class Element {
  @JsonKey(name: 'distance')
  final Distance? distance;

  @JsonKey(name: 'duration')
  final Duration? duration;

  @JsonKey(name: 'status')
  final String? status;

  Element({this.distance, this.duration, this.status});

  factory Element.fromJson(Map<String, dynamic> json) =>
      _$ElementFromJson(json);

  Map<String, dynamic> toJson() => _$ElementToJson(this);
}

@JsonSerializable()
class Prediction {
  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'matched_substrings')
  final List<MatchedSubstring?>? matchedSubstrings;

  @JsonKey(name: 'place_id')
  final String? placeId;

  @JsonKey(name: 'reference')
  final String? reference;

  @JsonKey(name: 'structured_formatting')
  final StructuredFormatting? structuredFormatting;

  @JsonKey(name: 'terms')
  final List<Term?>? terms;

  @JsonKey(name: 'types')
  final List<String?>? types;

  Prediction({
    this.description,
    this.matchedSubstrings,
    this.placeId,
    this.reference,
    this.structuredFormatting,
    this.terms,
    this.types,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) =>
      _$PredictionFromJson(json);

  Map<String, dynamic> toJson() => _$PredictionToJson(this);
}

@JsonSerializable()
class MatchedSubstring {
  @JsonKey(name: 'length')
  final int? length;

  @JsonKey(name: 'offset')
  final int? offset;

  MatchedSubstring({this.length, this.offset});

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) =>
      _$MatchedSubstringFromJson(json);

  Map<String, dynamic> toJson() => _$MatchedSubstringToJson(this);
}

@JsonSerializable()
class StructuredFormatting {
  @JsonKey(name: 'main_text')
  final String? mainText;

  @JsonKey(name: 'main_text_matched_substrings')
  final List<MainTextMatchedSubstring?>? mainTextMatchedSubstrings;

  @JsonKey(name: 'secondary_text')
  final String? secondaryText;

  StructuredFormatting({
    this.mainText,
    this.mainTextMatchedSubstrings,
    this.secondaryText,
  });

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) =>
      _$StructuredFormattingFromJson(json);

  Map<String, dynamic> toJson() => _$StructuredFormattingToJson(this);
}

@JsonSerializable()
class Term {
  @JsonKey(name: 'offset')
  final int? offset;

  @JsonKey(name: 'value')
  final String? value;

  Term({this.offset, this.value});

  factory Term.fromJson(Map<String, dynamic> json) => _$TermFromJson(json);

  Map<String, dynamic> toJson() => _$TermToJson(this);
}

@JsonSerializable()
class MainTextMatchedSubstring {
  @JsonKey(name: 'length')
  final int? length;

  @JsonKey(name: 'offset')
  final int? offset;

  MainTextMatchedSubstring({this.length, this.offset});

  factory MainTextMatchedSubstring.fromJson(Map<String, dynamic> json) =>
      _$MainTextMatchedSubstringFromJson(json);

  Map<String, dynamic> toJson() => _$MainTextMatchedSubstringToJson(this);
}

@JsonSerializable()
class GeocodeData {
  @JsonKey(name: 'address_components')
  final List<AddressComponent>? addressComponents;

  @JsonKey(name: 'formatted_address')
  final String? formattedAddress;

  @JsonKey(name: 'place_id')
  final String? placeId;

  @JsonKey(name: 'types')
  final List<String>? types;

  @JsonKey(name: 'geometry')
  final Geometry? geometry;

  GeocodeData({
    this.addressComponents,
    this.formattedAddress,
    this.placeId,
    this.types,
    this.geometry,
  });

  factory GeocodeData.fromJson(Map<String, dynamic> json) =>
      _$GeocodeDataFromJson(json);

  Map<String, dynamic> toJson() => _$GeocodeDataToJson(this);
}

@JsonSerializable()
class Geometry {
  @JsonKey(name: 'location')
  final GeoLocation? location;

  Geometry({this.location});

  factory Geometry.fromJson(Map<String, dynamic> json) =>
      _$GeometryFromJson(json);

  Map<String, dynamic> toJson() => _$GeometryToJson(this);
}

@JsonSerializable()
class GeoLocation {
  @JsonKey(name: 'lat')
  final double? lat;

  @JsonKey(name: 'lng')
  final double? lng;

  GeoLocation({this.lat, this.lng});

  factory GeoLocation.fromJson(Map<String, dynamic> json) =>
      _$GeoLocationFromJson(json);

  Map<String, dynamic> toJson() => _$GeoLocationToJson(this);
}

@JsonSerializable()
class AddressComponent {
  @JsonKey(name: 'long_name')
  final String? longName;

  @JsonKey(name: 'short_name')
  final String? shortName;

  @JsonKey(name: 'types')
  final List<String>? types;

  AddressComponent({this.longName, this.shortName, this.types});

  factory AddressComponent.fromJson(Map<String, dynamic> json) =>
      _$AddressComponentFromJson(json);

  Map<String, dynamic> toJson() => _$AddressComponentToJson(this);
}

@JsonSerializable()
class PlusCode {
  @JsonKey(name: 'compound_code')
  final String? compoundCode;

  @JsonKey(name: 'global_code')
  final String? globalCode;

  PlusCode({this.compoundCode, this.globalCode});

  factory PlusCode.fromJson(Map<String, dynamic> json) =>
      _$PlusCodeFromJson(json);

  Map<String, dynamic> toJson() => _$PlusCodeToJson(this);
}

@JsonSerializable()
class GeocodeRoutes {
  @JsonKey(name: 'bounds')
  final Bounds? bounds;

  @JsonKey(name: 'copyrights')
  final String? copyrights;

  @JsonKey(name: 'legs')
  final List<Leg>? legs;

  @JsonKey(name: 'overview_polyline')
  final OverviewPolyline? overviewPolyline;

  @JsonKey(name: 'summary')
  final String? summary;

  @JsonKey(name: 'warnings')
  final List<dynamic>? warnings;

  @JsonKey(name: 'waypoint_order')
  final List<dynamic>? waypointOrder;

  GeocodeRoutes({
    this.bounds,
    this.copyrights,
    this.legs,
    this.overviewPolyline,
    this.summary,
    this.warnings,
    this.waypointOrder,
  });

  factory GeocodeRoutes.fromJson(Map<String, dynamic> json) =>
      _$GeocodeRoutesFromJson(json);

  Map<String, dynamic> toJson() => _$GeocodeRoutesToJson(this);
}

@JsonSerializable()
class Bounds {
  @JsonKey(name: 'northeast')
  final Northeast? northeast;

  @JsonKey(name: 'southwest')
  final Southwest? southwest;

  Bounds({this.northeast, this.southwest});

  factory Bounds.fromJson(Map<String, dynamic> json) => _$BoundsFromJson(json);

  Map<String, dynamic> toJson() => _$BoundsToJson(this);
}

@JsonSerializable()
class Leg {
  @JsonKey(name: 'distance')
  final Distance? distance;

  @JsonKey(name: 'duration')
  final Duration? duration;

  @JsonKey(name: 'duration_in_traffic')
  final Duration? durationInTraffic;

  @JsonKey(name: 'end_address')
  final String? endAddress;

  @JsonKey(name: 'end_location')
  final EndLocation? endLocation;

  @JsonKey(name: 'start_address')
  final String? startAddress;

  @JsonKey(name: 'start_location')
  final StartLocation? startLocation;

  @JsonKey(name: 'steps')
  final List<Step>? steps;

  @JsonKey(name: 'traffic_speed_entry')
  final List<dynamic>? trafficSpeedEntry;

  @JsonKey(name: 'via_waypoint')
  final List<dynamic>? viaWaypoint;

  Leg({
    this.distance,
    this.duration,
    this.durationInTraffic,
    this.endAddress,
    this.endLocation,
    this.startAddress,
    this.startLocation,
    this.steps,
    this.trafficSpeedEntry,
    this.viaWaypoint,
  });

  factory Leg.fromJson(Map<String, dynamic> json) => _$LegFromJson(json);

  Map<String, dynamic> toJson() => _$LegToJson(this);
}

@JsonSerializable()
class OverviewPolyline {
  @JsonKey(name: 'points')
  final String? points;

  OverviewPolyline({this.points});

  factory OverviewPolyline.fromJson(Map<String, dynamic> json) =>
      _$OverviewPolylineFromJson(json);

  Map<String, dynamic> toJson() => _$OverviewPolylineToJson(this);
}

@JsonSerializable()
class Northeast {
  @JsonKey(name: 'lat')
  final double? lat;

  @JsonKey(name: 'lng')
  final double? lng;

  Northeast({this.lat, this.lng});

  factory Northeast.fromJson(Map<String, dynamic> json) =>
      _$NortheastFromJson(json);

  Map<String, dynamic> toJson() => _$NortheastToJson(this);
}

@JsonSerializable()
class Southwest {
  @JsonKey(name: 'lat')
  final double? lat;

  @JsonKey(name: 'lng')
  final double? lng;

  Southwest({this.lat, this.lng});

  factory Southwest.fromJson(Map<String, dynamic> json) =>
      _$SouthwestFromJson(json);

  Map<String, dynamic> toJson() => _$SouthwestToJson(this);
}

@JsonSerializable()
class Distance {
  @JsonKey(name: 'text')
  final String? text;

  @JsonKey(name: 'value')
  final int? value;

  Distance({this.text, this.value});

  factory Distance.fromJson(Map<String, dynamic> json) =>
      _$DistanceFromJson(json);

  Map<String, dynamic> toJson() => _$DistanceToJson(this);
}

@JsonSerializable()
class Duration {
  @JsonKey(name: 'text')
  final String? text;

  @JsonKey(name: 'value')
  final int? value;

  Duration({this.text, this.value});

  factory Duration.fromJson(Map<String, dynamic> json) =>
      _$DurationFromJson(json);

  Map<String, dynamic> toJson() => _$DurationToJson(this);
}

@JsonSerializable()
class EndLocation {
  @JsonKey(name: 'lat')
  final double? lat;

  @JsonKey(name: 'lng')
  final double? lng;

  EndLocation({this.lat, this.lng});

  factory EndLocation.fromJson(Map<String, dynamic> json) =>
      _$EndLocationFromJson(json);

  Map<String, dynamic> toJson() => _$EndLocationToJson(this);
}

@JsonSerializable()
class StartLocation {
  @JsonKey(name: 'lat')
  final double? lat;

  @JsonKey(name: 'lng')
  final double? lng;

  StartLocation({this.lat, this.lng});

  factory StartLocation.fromJson(Map<String, dynamic> json) =>
      _$StartLocationFromJson(json);

  Map<String, dynamic> toJson() => _$StartLocationToJson(this);
}

@JsonSerializable()
class Step {
  @JsonKey(name: 'distance')
  final Distance? distance;

  @JsonKey(name: 'duration')
  final Duration? duration;

  @JsonKey(name: 'end_location')
  final EndLocation? endLocation;

  @JsonKey(name: 'html_instructions')
  final String? htmlInstructions;

  @JsonKey(name: 'polyline')
  final Polyline? polyline;

  @JsonKey(name: 'start_location')
  final StartLocation? startLocation;

  @JsonKey(name: 'travel_mode')
  final String? travelMode;

  Step({
    this.distance,
    this.duration,
    this.endLocation,
    this.htmlInstructions,
    this.polyline,
    this.startLocation,
    this.travelMode,
  });

  factory Step.fromJson(Map<String, dynamic> json) => _$StepFromJson(json);

  Map<String, dynamic> toJson() => _$StepToJson(this);
}

@JsonSerializable()
class Polyline {
  @JsonKey(name: 'points')
  final String? points;

  Polyline({this.points});

  factory Polyline.fromJson(Map<String, dynamic> json) =>
      _$PolylineFromJson(json);

  Map<String, dynamic> toJson() => _$PolylineToJson(this);
}
