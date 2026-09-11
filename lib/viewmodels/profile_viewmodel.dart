import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/parse_response.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../core/constants/app_constants.dart';
import '../models/requests/entity_detail_request.dart';
import '../models/responses/auth/entity_detail_response.dart';

/// Profile screen state
class ProfileState {
  final Entity? entity;
  final bool isLoading;
  final bool isUploadingImage;
  final String? error;
  final String? successMessage;

  const ProfileState({
    this.entity,
    this.isLoading = false,
    this.isUploadingImage = false,
    this.error,
    this.successMessage,
  });

  ProfileState copyWith({
    Entity? entity,
    bool? isLoading,
    bool? isUploadingImage,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      entity: entity ?? this.entity,
      isLoading: isLoading ?? this.isLoading,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  /// Get full name
  String get fullName {
    final firstName = entity?.firstName ?? '';
    final lastName = entity?.lastName ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : getString(appStr.descriptionNotSet, 'description_not_set');
  }

  /// Get formatted phone number
  String get phoneNumber {
    final code = entity?.countryPhoneCode ?? '';
    final phone = entity?.phone ?? '';
    if (code.isNotEmpty && phone.isNotEmpty) {
      return '$code $phone';
    } else if (phone.isNotEmpty) {
      return phone;
    }
    return getString(appStr.descriptionNotSet, 'description_not_set');
  }

  /// Get email
  String get email => entity?.email ?? getString(appStr.descriptionNotSet, 'description_not_set');

  /// Whether user is a corporate user (entity type == 6)
  bool get isCorporateUser => entity?.type == EntityType.corporate;

  /// Get corporate entity details list
  List<TypeIdDetails> get corporateList => entity?.typeIdDetails ?? [];

  /// Get gender display text
  String get gender {
    final g = entity?.gender?.toLowerCase();
    if (g == 'male') return getString(appStr.descriptionMale, 'description_male');
    if (g == 'female') return getString(appStr.descriptionFemale, 'description_female');
    if (g != null && g.isNotEmpty) return g;
    return getString(appStr.descriptionNotSet, 'description_not_set');
  }
}

/// Profile screen ViewModel
class ProfileViewModel extends StateNotifier<ProfileState> {
  final SharedPreferenceManager _sharedPref;
  final AppRepository _appRepository;

  ProfileViewModel(this._sharedPref, this._appRepository)
      : super(const ProfileState()) {
    _loadProfileData();
  }

  /// Load profile data from shared preferences
  void _loadProfileData() {
    final entity = _sharedPref.getEntity();
    if (entity != null) {
      state = state.copyWith(entity: entity);
    }
  }

  /// Refresh profile data
  void refreshProfile() {
    _loadProfileData();
  }

  /// Upload profile picture
  Future<bool> uploadProfilePicture(String filePath) async {
    state = state.copyWith(isUploadingImage: true, clearError: true, clearSuccess: true);

    final response = await _appRepository.uploadProfilePicture(filePath);

    switch (response) {
      case Success():
        // Refresh entity data from server
        await _refreshEntityData();
        state = state.copyWith(
          isUploadingImage: false,
          successMessage: response.message ?? '',
        );
        return true;
      case Error():
        state = state.copyWith(
          isUploadingImage: false,
          error: response.error?.message ?? '',
        );
        return false;
      case Loading():
        return false;
    }
  }

  /// Refresh entity data from server
  Future<void> _refreshEntityData() async {
    final entity = _sharedPref.getEntity();
    final countryCode = entity?.countryCode ?? 'IN';

    final request = EntityDetailRequest(countryCode: countryCode);
    final response = await _appRepository.getEntityDetail(request);

    switch (response) {
      case Success<EntityDetailResponse>():
        final data = response.data;
        if (data != null) {
          parseEntityDetailResponse(data, _sharedPref);
          _loadProfileData();
        }
      case Error():
        // Silently fail - image was already uploaded
        break;
      case Loading():
        break;
    }
  }
}

/// Provider for ProfileViewModel
final profileViewModelProvider =
    StateNotifierProvider.autoDispose<ProfileViewModel, ProfileState>((ref) {
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  final appRepository = ref.watch(appRepositoryProvider);

  return ProfileViewModel(sharedPref, appRepository);
});
