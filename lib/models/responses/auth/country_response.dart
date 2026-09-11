import 'package:json_annotation/json_annotation.dart';

part 'country_response.g.dart';

@JsonSerializable()
class CountryResponse {
  final List<Country>? countries;

  CountryResponse({
    this.countries,
  });

  factory CountryResponse.fromJson(Map<String, dynamic> json) =>
      _$CountryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CountryResponseToJson(this);
}

@JsonSerializable()
class Country {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final List<String>? phoneCodes;
  final String? currencyCode;
  final String? currencySign;
  final String? alpha2;
  final String? code;
  final String? code2;
  final List<String>? timezones;
  final bool? isBusiness;
  final String? phoneCode;

  Country({
    this.id,
    this.name,
    this.phoneCodes,
    this.currencyCode,
    this.currencySign,
    this.alpha2,
    this.code,
    this.code2,
    this.timezones,
    this.isBusiness,
    this.phoneCode,
  });

  factory Country.fromJson(Map<String, dynamic> json) =>
      _$CountryFromJson(json);

  Map<String, dynamic> toJson() => _$CountryToJson(this);

  Country copyWith({List<String>? phoneCodes}) {
    return Country(
      id: id,
      name: name,
      phoneCodes: phoneCodes ?? this.phoneCodes,
      currencyCode: currencyCode,
      currencySign: currencySign,
      alpha2: alpha2,
      code: code,
      code2: code2,
      timezones: timezones,
      isBusiness: isBusiness,
      phoneCode: phoneCode,
    );
  }

  /// Get the phone code - falls back to first item in phoneCodes array if phoneCode is null
  String get displayPhoneCode {
    if (phoneCode != null && phoneCode!.isNotEmpty) {
      return phoneCode!;
    }
    if (phoneCodes != null && phoneCodes!.isNotEmpty) {
      return phoneCodes!.first;
    }
    return '';
  }

  bool doesMatchSearchQuery(String query) {
    final matchingCombinations = [
      name ?? '',
      phoneCode ?? '',
      code ?? '',
    ];

    return matchingCombinations.any(
      (it) => it.toLowerCase().contains(query.toLowerCase()),
    );
  }
}
