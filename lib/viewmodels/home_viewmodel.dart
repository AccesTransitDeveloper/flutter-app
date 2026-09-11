import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/app_strings.dart';
import '../core/managers/live_activity_manager.dart';
import '../core/managers/location_manager.dart';
import '../core/managers/notification_manager.dart';
import '../core/managers/socket_manager.dart';
import '../core/map/map.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../data/repository/app_repository.dart';
import '../data/api/response_state.dart';
import '../models/responses/setting/missing_information_response.dart';
import 'document_viewmodel.dart';
import '../models/requests/business_type_request.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/requests/promo_code_list_request.dart';
import '../models/responses/booking/promo_code_response.dart';
import '../models/responses/auth/entity_detail_response.dart';
import '../models/responses/booking/check_business_response.dart';
import '../models/responses/booking/get_vehicle_type_response.dart';
import '../models/ride_type_item.dart';

/// Home screen state
class HomeState {
  final String? userName;
  final Entity? entity;
  final LatLng? currentLocation;
  final String? currentAddress;
  final String? countryCode;
  final DestinationAddress? pickupAddress;
  final bool isLoadingLocation;
  final bool isLocationPermissionDenied;
  final bool isLoadingBusinessTypes;
  final bool isLoadingVehicleTypes;
  final bool isSigningOut;
  final String? error;
  final List<BusinessTypeSetting>? businessTypeSettings;
  final List<int>? businessTypes;
  final String? countryId;
  final String? cityId;
  final GetVehicleTypeResponse? vehicleTypeResponse;
  final List<RideTypeItem> rideTypeItems;
  final List<PromoCodes> promoOffersList;

  // Missing information
  final List<MissingInfoItem> missingInfoItems;
  final bool showMissingInfoSheet;
  final bool showApprovalScreen;

  const HomeState({
    this.userName,
    this.entity,
    this.currentLocation,
    this.currentAddress,
    this.countryCode,
    this.pickupAddress,
    this.isLoadingLocation = false,
    this.isLocationPermissionDenied = false,
    this.isLoadingBusinessTypes = false,
    this.isLoadingVehicleTypes = false,
    this.isSigningOut = false,
    this.error,
    this.businessTypeSettings,
    this.businessTypes,
    this.countryId,
    this.cityId,
    this.vehicleTypeResponse,
    this.rideTypeItems = const [],
    this.promoOffersList = const [],
    this.missingInfoItems = const [],
    this.showMissingInfoSheet = false,
    this.showApprovalScreen = false,
  });

  HomeState copyWith({
    String? userName,
    Entity? entity,
    LatLng? currentLocation,
    String? currentAddress,
    String? countryCode,
    DestinationAddress? pickupAddress,
    bool? isLoadingLocation,
    bool? isLocationPermissionDenied,
    bool? isLoadingBusinessTypes,
    bool? isLoadingVehicleTypes,
    bool? isSigningOut,
    String? error,
    List<BusinessTypeSetting>? businessTypeSettings,
    List<int>? businessTypes,
    String? countryId,
    String? cityId,
    GetVehicleTypeResponse? vehicleTypeResponse,
    List<RideTypeItem>? rideTypeItems,
    List<PromoCodes>? promoOffersList,
    List<MissingInfoItem>? missingInfoItems,
    bool? showMissingInfoSheet,
    bool? showApprovalScreen,
    bool clearError = false,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      entity: entity ?? this.entity,
      currentLocation: currentLocation ?? this.currentLocation,
      currentAddress: currentAddress ?? this.currentAddress,
      countryCode: countryCode ?? this.countryCode,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isLocationPermissionDenied: isLocationPermissionDenied ?? this.isLocationPermissionDenied,
      isLoadingBusinessTypes: isLoadingBusinessTypes ?? this.isLoadingBusinessTypes,
      isLoadingVehicleTypes: isLoadingVehicleTypes ?? this.isLoadingVehicleTypes,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      error: clearError ? null : (error ?? this.error),
      businessTypeSettings: businessTypeSettings ?? this.businessTypeSettings,
      businessTypes: businessTypes ?? this.businessTypes,
      countryId: countryId ?? this.countryId,
      cityId: cityId ?? this.cityId,
      vehicleTypeResponse: vehicleTypeResponse ?? this.vehicleTypeResponse,
      rideTypeItems: rideTypeItems ?? this.rideTypeItems,
      promoOffersList: promoOffersList ?? this.promoOffersList,
      missingInfoItems: missingInfoItems ?? this.missingInfoItems,
      showMissingInfoSheet: showMissingInfoSheet ?? this.showMissingInfoSheet,
      showApprovalScreen: showApprovalScreen ?? this.showApprovalScreen,
    );
  }

  /// Check if taxi business type is available
  bool get hasTaxiBusinessType =>
      businessTypes?.contains(BusinessType.taxi) ?? false;
}

/// Item for missing information list (used in UI)
class MissingInfoItem {
  final String title;
  final String description;
  final int id;
  final bool isEnabled;

  const MissingInfoItem({
    required this.title,
    required this.description,
    required this.id,
    this.isEnabled = true,
  });
}

/// Home screen ViewModel
class HomeViewModel extends StateNotifier<HomeState> {
  final MapInterface _mapManager;
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;
  final LocationManager _locationManager;
  final SocketManager _socketManager;

  HomeViewModel(
    this._mapManager,
    this._appRepository,
    this._sharedPref,
    this._locationManager,
    this._socketManager,
  ) : super(const HomeState()) {
    debugPrint('🏠 HomeViewModel created');
    _loadUserName();
    // Delay location fetch until after first frame renders (map needs time to initialize)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      getCurrentLocation();
      getInformationStatus();
    });
  }

  void _loadUserName() {
    final entity = _sharedPref.getEntity();
    if (entity != null) {
      final firstName = entity.firstName ?? '';
      final lastName = entity.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();
      state = state.copyWith(
        userName: fullName.isNotEmpty ? fullName : null,
        entity: entity,
      );
    }
  }

  /// Get current location, then geocode it
  Future<void> getCurrentLocation() async {
    debugPrint('🏠 getCurrentLocation called');
    state = state.copyWith(isLoadingLocation: true, isLoadingBusinessTypes: true, clearError: true);

    final result = await _locationManager.getCurrentLocation();
    debugPrint('🏠 getCurrentLocation result: $result');

    switch (result) {
      case LocationSuccess():
        final location = LatLng(
          result.location.latitude,
          result.location.longitude,
        );
        state = state.copyWith(
          currentLocation: location,
        );
        // Geocode the location - this will also fetch business types
        _reverseGeocode(location);

      case LocationPermissionDenied():
        debugPrint('🏠 Location permission denied');
        state = state.copyWith(
          isLoadingLocation: false,
          isLocationPermissionDenied: true,
          isLoadingBusinessTypes: false,
        );

      case LocationServiceDisabled():
        debugPrint('🏠 Location service disabled');
        state = state.copyWith(
          isLoadingLocation: false,
          isLoadingBusinessTypes: false,
          error: 'Location services are disabled',
        );

      case LocationError():
        debugPrint('🏠 Location error: ${result.message}');
        state = state.copyWith(
          isLoadingLocation: false,
          isLoadingBusinessTypes: false,
          error: result.message,
        );
    }
  }

  /// Reverse geocode location to get address and country code, then fetch business types
  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final pickupAddress = await _mapManager.getPlaceDetailWithCoordinates(
        location.latitude,
        location.longitude,
      );

      debugPrint('🏠 Geocode success: ${pickupAddress.address}, countryCode: ${pickupAddress.countryCode}');

      state = state.copyWith(
        currentAddress: pickupAddress.address,
        countryCode: pickupAddress.countryCode,
        pickupAddress: pickupAddress,
        isLoadingLocation: false,
      );

      // Animate camera after geocode response
      debugPrint('🏠 Animating camera to $location');
      _mapManager.animateCamera(location, zoom: 15);

      // Now fetch business types with location data
      final countryCode = pickupAddress.countryCode;
      if (countryCode != null && countryCode.isNotEmpty) {
        _fetchBusinessTypes(location, countryCode);
      } else {
        state = state.copyWith(isLoadingBusinessTypes: false);
      }
    } catch (e) {
      debugPrint('🏠 Reverse geocode error: $e');
      state = state.copyWith(isLoadingLocation: false, isLoadingBusinessTypes: false);
      // Still animate camera even on error
      _mapManager.animateCamera(location, zoom: 15);
    }
  }

  /// Fetch business types based on location
  Future<void> _fetchBusinessTypes(LatLng location, String countryCode) async {
    debugPrint('🏠 Fetching business types for countryCode: $countryCode');

    final request = BusinessTypeRequest(
      address: CheckBusinessAddress(
        countryCode: countryCode,
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );

    final response = await _appRepository.getBusinessType(request);

    switch (response) {
      case Success():
        final data = response.data;
        debugPrint('🏠 Business types fetched: ${data?.businessTypeSettings?.length ?? 0} settings, ${data?.businessTypes?.length ?? 0} types');
        debugPrint('🏠 Business types list: ${data?.businessTypes}');

        state = state.copyWith(
          businessTypeSettings: data?.businessTypeSettings,
          businessTypes: data?.businessTypes,
          countryId: data?.countryId,
          cityId: data?.cityId,
          isLoadingBusinessTypes: false,
        );

        // If taxi business type is available, fetch vehicle types
        if (data?.businessTypes?.contains(BusinessType.taxi) == true) {
          debugPrint('🏠 Taxi business type available, fetching vehicle types');
          _fetchVehicleTypes(location, countryCode);
        }

      case Error():
        debugPrint('🏠 Business types error: ${response.message}');
        state = state.copyWith(
          isLoadingBusinessTypes: false,
        );

      case Loading():
        break;
    }
  }

  /// Fetch vehicle types for taxi business
  Future<void> _fetchVehicleTypes(LatLng location, String countryCode) async {
    debugPrint('🏠 Fetching vehicle types for countryCode: $countryCode');
    state = state.copyWith(isLoadingVehicleTypes: true);

    // Use the stored pickupAddress from geocode response
    final pickupAddress = state.pickupAddress;
    if (pickupAddress == null) {
      debugPrint('🏠 No pickup address available');
      state = state.copyWith(isLoadingVehicleTypes: false);
      return;
    }

    final request = GetVehicleTypesRequest(
      countryCode: countryCode,
      pickupAddress: pickupAddress,
      destinationAddresses: [],
      businessType: BusinessType.taxi,
    );

    final response = await _appRepository.getVehicleTypes(request);

    switch (response) {
      case Success():
        final data = response.data;
        debugPrint('🏠 Vehicle types API SUCCESS');
        debugPrint('🏠 Vehicle types data is null: ${data == null}');
        debugPrint('🏠 Vehicle types fetched: normalList=${data?.normalList?.length ?? 0}, rentalList=${data?.rentalList?.length ?? 0}, shareList=${data?.shareList?.length ?? 0}');
        debugPrint('🏠 Vehicle types bookingTypeOrder: ${data?.bookingTypeOrder}');
        debugPrint('🏠 Vehicle types bookingTypeLogo: ${data?.bookingTypeLogo}');

        // Build ride type items list
        final rideTypeItems = _buildRideTypeItems(data);
        debugPrint('🏠 Built ${rideTypeItems.length} ride type items');
        for (int i = 0; i < rideTypeItems.length; i++) {
          debugPrint('🏠 rideTypeItem[$i]: type=${rideTypeItems[i].type}, name=${rideTypeItems[i].typeName}, imgUrl=${rideTypeItems[i].imgUrl}');
        }

        state = state.copyWith(
          vehicleTypeResponse: data,
          rideTypeItems: rideTypeItems,
          isLoadingVehicleTypes: false,
        );
        debugPrint('🏠 State updated with ${state.rideTypeItems.length} rideTypeItems');

        // Fetch promo codes if ads are enabled
        if (data?.citySetting?.isAds == true && state.countryId != null) {
          _fetchPromoCodes();
        }

      case Error():
        debugPrint('🏠 Vehicle types ERROR case hit');
        debugPrint('🏠 Vehicle types error message: ${response.message}');
        debugPrint('🏠 Vehicle types error code: ${response.responseCode}');
        debugPrint('🏠 Vehicle types error details: ${response.error}');
        state = state.copyWith(isLoadingVehicleTypes: false);

      case Loading():
        break;
    }
  }

  /// Whether this city has any vehicle for [type]. Mirrors native's per-type
  /// `isNullOrEmpty` check on the matching list.
  bool _hasVehiclesFor(RideType type, GetVehicleTypeResponse response) {
    final list = switch (type) {
      RideType.normal => response.normalList,
      RideType.rental => response.rentalList,
      RideType.sharing => response.shareList,
      RideType.fixGroup => response.fixGroupBookingList,
    };
    return list != null && list.isNotEmpty;
  }

  /// Build ride type items list from vehicle types response
  List<RideTypeItem> _buildRideTypeItems(GetVehicleTypeResponse? response) {
    debugPrint('🏠 _buildRideTypeItems: START');

    if (response == null) {
      debugPrint('🏠 _buildRideTypeItems: response is null - returning empty list');
      return [];
    }

    final List<RideTypeItem> items = [];
    final bookingTypeOrder = response.bookingTypeOrder;
    final bookingTypeLogo = response.bookingTypeLogo;
    final darkBookingTypeLogo = response.darkBookingTypeLogo;

    debugPrint('🏠 _buildRideTypeItems: bookingTypeOrder=$bookingTypeOrder (type: ${bookingTypeOrder.runtimeType})');
    debugPrint('🏠 _buildRideTypeItems: bookingTypeLogo=$bookingTypeLogo');
    debugPrint('🏠 _buildRideTypeItems: darkBookingTypeLogo=$darkBookingTypeLogo');
    debugPrint('🏠 _buildRideTypeItems: normalList count=${response.normalList?.length ?? 0}');

    // Check theme preference
    final theme = _sharedPref.getTheme();
    final isDarkMode = theme == 'dark';
    debugPrint('🏠 _buildRideTypeItems: theme=$theme, isDarkMode=$isDarkMode');

    // Base ride types with localized names
    final baseRideTypes = [
      RideTypeItem(
        typeName: getString(appStr.descriptionNormal, 'description_normal'),
        type: RideType.normal,
      ),
      RideTypeItem(
        typeName: getString(appStr.descriptionRental, 'description_rental'),
        type: RideType.rental,
      ),
      RideTypeItem(
        typeName: getString(appStr.descriptionShare, 'description_share'),
        type: RideType.sharing,
      ),
      // RideTypeItem(
      //   typeName: getString(appStr.descriptionFixGroupBooking, 'description_fix_group_booking'),
      //   type: RideType.fixGroup,
      // ),
    ];
    debugPrint('🏠 _buildRideTypeItems: baseRideTypes count=${baseRideTypes.length}');
    for (final rt in baseRideTypes) {
      debugPrint('🏠 _buildRideTypeItems: baseRideType - type=${rt.type}, name=${rt.typeName}');
    }

    // Filter and order based on bookingTypeOrder
    if (bookingTypeOrder != null && bookingTypeOrder.isNotEmpty) {
      debugPrint('🏠 _buildRideTypeItems: processing ${bookingTypeOrder.length} booking types from order');
      for (final order in bookingTypeOrder) {
        debugPrint('🏠 _buildRideTypeItems: checking order=$order (type: ${order.runtimeType})');
        if (order == null) {
          debugPrint('🏠 _buildRideTypeItems: order is null, skipping');
          continue;
        }

        final baseType = baseRideTypes.where((rt) => rt.type.value == order).firstOrNull;
        debugPrint('🏠 _buildRideTypeItems: order=$order, baseType found=${baseType != null}, baseType name=${baseType?.typeName}');
        // bookingTypeOrder only says what order to show them in — a type with
        // no vehicles in this city still appears there. Native gates each one
        // on its vehicle list being non-empty and drops the rest
        // (HomeViewModel.kt: `.filter { rideType -> rideType.isVisible }`), so
        // Rajkot shows Normal alone even though the order lists all three.
        if (baseType != null && _hasVehiclesFor(baseType.type, response)) {
          // Get logo based on theme
          final logoKey = order.toString();
          final imgUrl = isDarkMode
              ? (darkBookingTypeLogo?[logoKey] ?? bookingTypeLogo?[logoKey])
              : bookingTypeLogo?[logoKey];
          debugPrint('🏠 _buildRideTypeItems: logoKey=$logoKey, imgUrl=$imgUrl');

          items.add(baseType.copyWith(imgUrl: imgUrl));
          debugPrint('🏠 _buildRideTypeItems: added item for order=$order, items count now=${items.length}');
        }
      }
    } else {
      debugPrint('🏠 _buildRideTypeItems: bookingTypeOrder is null or empty - bookingTypeOrder=$bookingTypeOrder');
    }

    // Native appends the individual normal vehicles the city wants surfaced —
    // `cityRideTypeList.plus(normalVehicles)` (HomeViewModel.kt:2055). Dropping
    // this was my mistake: it is the only path that adds an entry beyond the
    // booking types, and it is gated on the admin's isShowInMainScreen flag.
    final normalList = response.normalList;
    if (normalList != null) {
      for (final vehicle in normalList) {
        if (vehicle.vehicleTypeDetail?.isShowInMainScreen != true) continue;
        items.add(RideTypeItem(
          imgUrl: vehicle.vehicleTypeDetail?.imageUrl,
          typeName: vehicle.vehicleTypeDetail?.name ?? '',
          type: RideType.normal,
          vehicleType: vehicle,
        ));
      }
    }

    return items;
  }

  /// Fetch promo codes for the current city
  Future<void> _fetchPromoCodes() async {
    final request = PromoCodeListRequest(
      cityId: state.cityId,
      countryId: state.countryId,
      businessType: BusinessType.taxi,
    );

    final response = await _appRepository.getPromoCodes(request);

    switch (response) {
      case Success():
        final promos = response.data?.promoCodes ?? [];
        debugPrint('🏠 Promo codes fetched: ${promos.length}');
        state = state.copyWith(promoOffersList: promos);

      case Error():
        debugPrint('🏠 Promo codes error: ${response.message}');

      case Loading():
        break;
    }
  }

  /// Build default ride type items (fallback when location/business API fails)


  /// Sign out user
  Future<bool> signOut() async {
    state = state.copyWith(isSigningOut: true);

    try {
      await _appRepository.signOut();
      // Cleanup: unsubscribe topic, cancel notifications, stop live activities, disconnect socket
      await NotificationManager.instance.unsubscribeFromCurrentTopic();
      await NotificationManager.instance.cancelAllNotifications();
      await LiveActivityManager.instance.stopAllActivities();
      NotificationManager.instance.onTokenRefreshed = null;
      NotificationManager.instance.onNotificationTapped = null;
      _socketManager.offAllEvents();
      _socketManager.disconnect();
      await _sharedPref.signOut();
      state = state.copyWith(isSigningOut: false);
      return true;
    } catch (e) {
      debugPrint('🏠 SignOut error: $e');
      state = state.copyWith(isSigningOut: false);
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ============= Missing Information =============

  /// Fetch information status from API
  Future<void> getInformationStatus() async {
    final entity = _sharedPref.getEntity();
    if (entity == null) {
      debugPrint('🏠 getInformationStatus: entity is null, skipping');
      return;
    }

    final status = entity.status;
    debugPrint('🏠 getInformationStatus: entity status=$status');

    // Blocked users are handled in MainScreen — skip
    if (status == EntityTypeStatus.block) {
      debugPrint('🏠 getInformationStatus: user is blocked, skipping');
      return;
    }

    // Declined users — show declined screen directly without API call
    if (status == EntityTypeStatus.decline) {
      debugPrint('🏠 getInformationStatus: user is declined, showing declined screen');
      state = state.copyWith(
        showMissingInfoSheet: false,
        showApprovalScreen: true,
        missingInfoItems: [
          MissingInfoItem(
            title: getString(appStr.errorNotApprovedYet, 'error_not_approved_yet'),
            description: getString(appStr.descriptionYourAccountIsDeclined, 'description_your_account_is_declined'),
            id: 1,
          ),
        ],
      );
      return;
    }

    debugPrint('🏠 getInformationStatus: calling API...');
    final response = await _appRepository.getInformationStatus();

    switch (response) {
      case Success<MissingInformationResponse>():
        final informationStatus = response.data?.informationStatus;
        debugPrint('🏠 getInformationStatus: API success, informationStatus=${informationStatus != null}');
        if (informationStatus == null) return;

        debugPrint('🏠 getInformationStatus: profileStatus=${informationStatus.profileStatus}, '
            'documentStatus=${informationStatus.documentStatus}, '
            'creditStatus=${informationStatus.creditStatus}, '
            'typeStatus=${informationStatus.typeStatus}');
        _processInformationStatus(informationStatus);

      case Error<MissingInformationResponse>():
        debugPrint('🏠 getInformationStatus error: ${response.message}');

      case Loading<MissingInformationResponse>():
        break;
    }
  }

  void _processInformationStatus(InformationStatus info) {
    final missingItems = _buildMissingInfoList(info);
    var isShowBottomSheet = false;

    if (info.documentStatus == DocumentStatus.pending.value) {
      debugPrint('🏠 _processInformationStatus: documentStatus is PENDING → show bottom sheet');
      isShowBottomSheet = true;
    }
    if (!info.profileStatus) {
      debugPrint('🏠 _processInformationStatus: profileStatus is false → show bottom sheet');
      isShowBottomSheet = true;
    }
    final entity = _sharedPref.getEntity();
    final setting = _sharedPref.getSetting();
    if ((entity?.gender ?? '').isEmpty && setting?.isAllowGenderSelection == true) {
      debugPrint('🏠 _processInformationStatus: gender empty & gender selection allowed → show bottom sheet');
      isShowBottomSheet = true;
    }

    debugPrint('🏠 _processInformationStatus: isShowBottomSheet=$isShowBottomSheet, missingItems=${missingItems.length}');

    if (isShowBottomSheet) {
      if (missingItems.isNotEmpty) {
        debugPrint('🏠 _processInformationStatus: → Mode A (missing info sheet)');
        state = state.copyWith(
          showMissingInfoSheet: true,
          showApprovalScreen: false,
          missingInfoItems: missingItems,
        );
      }
    } else {
      final approvalItems = _buildApprovalList(info);
      debugPrint('🏠 _processInformationStatus: approvalItems=${approvalItems.length}');
      if (approvalItems.isNotEmpty) {
        debugPrint('🏠 _processInformationStatus: → Mode B (approval screen)');
        state = state.copyWith(
          showMissingInfoSheet: false,
          showApprovalScreen: true,
          missingInfoItems: approvalItems,
        );
      } else {
        debugPrint('🏠 _processInformationStatus: → All clear, no missing info or approval needed');
        state = state.copyWith(
          showMissingInfoSheet: false,
          showApprovalScreen: false,
          missingInfoItems: [],
        );
      }
    }
  }

  /// Build list of actionable missing information items (Mode A)
  List<MissingInfoItem> _buildMissingInfoList(InformationStatus info) {
    final items = <MissingInfoItem>[];

    if (!info.profileStatus) {
      items.add(MissingInfoItem(
        title: getString(appStr.headingProfile, 'heading_profile'),
        description: getString(appStr.errorPleaseUpdateProfile, 'error_please_update_profile'),
        id: 1,
      ));
    }

    if (info.documentStatus == DocumentStatus.pending.value) {
      items.add(MissingInfoItem(
        title: getString(appStr.headingDocument, 'heading_document'),
        description: getString(appStr.errorPleaseUpdateMandatoryDocument, 'error_please_update_mandatory_document'),
        id: 2,
        isEnabled: info.profileStatus,
      ));
    }

    final entity = _sharedPref.getEntity();
    final setting = _sharedPref.getSetting();
    if ((entity?.gender ?? '').isEmpty && setting?.isAllowGenderSelection == true) {
      items.add(MissingInfoItem(
        title: getString(appStr.headingGender, 'heading_gender'),
        description: getString(appStr.errorPleaseSelectGender, 'error_please_select_gender'),
        id: 3,
      ));
    }

    return items;
  }

  /// Build list of approval-pending items (Mode B — user can't act)
  List<MissingInfoItem> _buildApprovalList(InformationStatus info) {
    final items = <MissingInfoItem>[];
    final docStatus = info.documentStatus;

    if (docStatus == DocumentStatus.uploaded.value) {
      items.add(MissingInfoItem(
        title: getString(appStr.errorNotApprovedYet, 'error_not_approved_yet'),
        description: getString(appStr.errorAdminReviewYourDocument, 'error_admin_review_your_document'),
        id: 1,
      ));
    } else if (docStatus == DocumentStatus.rejected.value) {
      items.add(MissingInfoItem(
        title: getString(appStr.errorNotApprovedYet, 'error_not_approved_yet'),
        description: getString(appStr.errorAdminDocRejected, 'error_admin_doc_rejected'),
        id: 1,
      ));
    } else if (docStatus == DocumentStatus.expired.value) {
      items.add(MissingInfoItem(
        title: getString(appStr.errorNotApprovedYet, 'error_not_approved_yet'),
        description: getString(appStr.errorAdminDocExpired, 'error_admin_doc_expired'),
        id: 1,
      ));
    }

    return items;
  }

}

/// Provider for HomeViewModel
final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  // Create map manager instance for geocoding operations
  final mapManager = ref.read(mapManagerProvider)();
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  const locationManager = LocationManager.instance;

  // Dispose map manager when provider is disposed
  ref.onDispose(() {
    mapManager.dispose();
  });

  final socketManager = ref.read(socketManagerProvider);

  return HomeViewModel(mapManager, appRepository, sharedPref, locationManager, socketManager);
});
