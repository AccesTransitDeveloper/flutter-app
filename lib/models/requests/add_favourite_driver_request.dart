import 'package:json_annotation/json_annotation.dart';

part 'add_favourite_driver_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AddFavouriteDriverRequest {
  final dynamic driverId;

  AddFavouriteDriverRequest({
    this.driverId,
  });

  factory AddFavouriteDriverRequest.fromJson(Map<String, dynamic> json) =>
      _$AddFavouriteDriverRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddFavouriteDriverRequestToJson(this);
}
