import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../../core/providers/app_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../models/responses/location/location_response.dart';
import '../../models/responses/location/share_link_response.dart';
import '../api/response_state.dart';

class SocketRepository {
  final ApiClient apiClient;

  SocketRepository(this.apiClient);

  /// Get location for a booking
  Future<ResponseState<LocationResponse>> getLocation(String bookingId) async {
    final path = SocketApiEndpoint.location.replaceAll('{bookingId}', bookingId);
    return apiClient.get<LocationResponse>(
      path,
      fromJsonT: (json) => LocationResponse.fromJson(json),
    );
  }

  /// Get share link for a booking
  Future<ResponseState<ShareLinkResponse>> getShareLink(String bookingId) async {
    final path = SocketApiEndpoint.shareLink.replaceAll('{bookingId}', bookingId);
    return apiClient.get<ShareLinkResponse>(
      path,
      fromJsonT: (json) => ShareLinkResponse.fromJson(json),
    );
  }

  /// Upload chat attachment (image)
  Future<ResponseState<dynamic>> chatAttachment({
    required String chatId,
    required String referenceId,
    required String chatType,
    required String imagePath,
  }) async {
    return apiClient.putMultipart<dynamic>(
      SocketApiEndpoint.chatAttachment,
      filePath: imagePath,
      fileFieldName: 'image',
      fields: {
        'chatId': chatId,
        'referenceId': referenceId,
        'chatType': chatType,
      },
    );
  }
}

final socketRepositoryProvider = Provider<SocketRepository>((ref) {
  final apiClient = ref.watch(socketApiClientProvider);
  return SocketRepository(apiClient);
});
