import 'package:json_annotation/json_annotation.dart';

part 'share_link_response.g.dart';

@JsonSerializable()
class ShareLinkResponse {
  final String? link;

  ShareLinkResponse({
    this.link,
  });

  factory ShareLinkResponse.fromJson(Map<String, dynamic> json) =>
      _$ShareLinkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ShareLinkResponseToJson(this);
}
