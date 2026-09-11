import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart' as constants;
import '../core/localization/app_strings.dart';
import '../core/managers/live_activity_manager.dart';
import '../core/managers/notification_manager.dart';
import '../core/managers/socket_manager.dart';
import '../core/utils/device_info_helper.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../data/repository/app_repository.dart';
import '../data/api/response_state.dart';
import '../models/requests/generate_otp_request.dart';
import '../models/requests/verify_otp_request.dart';
import '../models/responses/auth/entity_detail_response.dart';
import '../models/requests/set_language_request.dart';
import '../models/requests/emergency_contact_request.dart';
import '../models/responses/setting/emergency_contact_response.dart' as api;
import '../models/responses/auth/country_response.dart';
import '../core/theme/theme_notifier.dart';

/// Auth option for delete account verification (password / email OTP / phone OTP)
class DeleteAuthOption {
  final String label;
  final int? sendMode; // null = password, OtpSendMode.sms or .email
  final bool isSelected;

  const DeleteAuthOption({
    required this.label,
    this.sendMode,
    this.isSelected = false,
  });

  DeleteAuthOption copyWith({bool? isSelected}) => DeleteAuthOption(
        label: label,
        sendMode: sendMode,
        isSelected: isSelected ?? this.isSelected,
      );
}

/// Settings screen state
class SettingsState {
  final Entity? entity;
  final bool isLoading;
  final String? error;
  final String? snackBarMessage;

  // Theme
  final AppThemeMode selectedTheme;
  final bool showThemeBottomSheet;

  // Language
  final String selectedLanguage;
  final List<LanguageItem> languageList;
  final bool showLanguageBottomSheet;
  final bool isLanguageLoading;

  // Emergency Contacts
  final List<EmergencyContactItem> emergencyContacts;
  final bool showAddContactBottomSheet;
  final bool isContactLoading;
  final String contactName;
  final String contactPhone;
  final String contactCountryCode;
  final String? editingContactId;
  final List<Country> countries;
  final List<Country> multiplePhoneCodeCountryList;
  final bool showContactCountryPhoneCodeBottomSheet;

  // Delete Account
  final bool showDeleteAccountBottomSheet;
  final bool showAuthOptionsBottomSheet;
  final bool showVerifyPasswordBottomSheet;
  final bool showDeleteOtpBottomSheet;
  final bool isDeleteLoading;
  final List<DeleteAuthOption> authOptions;
  final String deletePassword;
  final String deleteOtp;
  final int? deleteOtpSendTo;
  final String deleteOtpSentToDisplay;
  final GenerateOtpRequest? deleteResendOtpRequest;

  // Logout
  final bool showLogoutBottomSheet;
  final bool isLogoutLoading;

  // Navigation flags
  final bool navigateToLogin;

  // App Version
  final String appVersion;

  const SettingsState({
    this.entity,
    this.isLoading = false,
    this.error,
    this.snackBarMessage,
    this.appVersion = '',
    this.selectedTheme = AppThemeMode.system,
    this.showThemeBottomSheet = false,
    this.selectedLanguage = 'English',
    this.languageList = const [],
    this.showLanguageBottomSheet = false,
    this.isLanguageLoading = false,
    this.emergencyContacts = const [],
    this.showAddContactBottomSheet = false,
    this.isContactLoading = false,
    this.contactName = '',
    this.contactPhone = '',
    this.contactCountryCode = '',
    this.editingContactId,
    this.countries = const [],
    this.multiplePhoneCodeCountryList = const [],
    this.showContactCountryPhoneCodeBottomSheet = false,
    this.showDeleteAccountBottomSheet = false,
    this.showAuthOptionsBottomSheet = false,
    this.showVerifyPasswordBottomSheet = false,
    this.showDeleteOtpBottomSheet = false,
    this.isDeleteLoading = false,
    this.authOptions = const [],
    this.deletePassword = '',
    this.deleteOtp = '',
    this.deleteOtpSendTo,
    this.deleteOtpSentToDisplay = '',
    this.deleteResendOtpRequest,
    this.showLogoutBottomSheet = false,
    this.isLogoutLoading = false,
    this.navigateToLogin = false,
  });

  SettingsState copyWith({
    Entity? entity,
    bool? isLoading,
    String? error,
    String? snackBarMessage,
    String? appVersion,
    AppThemeMode? selectedTheme,
    bool? showThemeBottomSheet,
    String? selectedLanguage,
    List<LanguageItem>? languageList,
    bool? showLanguageBottomSheet,
    bool? isLanguageLoading,
    List<EmergencyContactItem>? emergencyContacts,
    bool? showAddContactBottomSheet,
    bool? isContactLoading,
    String? contactName,
    String? contactPhone,
    String? contactCountryCode,
    String? editingContactId,
    List<Country>? countries,
    List<Country>? multiplePhoneCodeCountryList,
    bool? showContactCountryPhoneCodeBottomSheet,
    bool? showDeleteAccountBottomSheet,
    bool? showAuthOptionsBottomSheet,
    bool? showVerifyPasswordBottomSheet,
    bool? showDeleteOtpBottomSheet,
    bool? isDeleteLoading,
    List<DeleteAuthOption>? authOptions,
    String? deletePassword,
    String? deleteOtp,
    int? deleteOtpSendTo,
    String? deleteOtpSentToDisplay,
    GenerateOtpRequest? deleteResendOtpRequest,
    bool? showLogoutBottomSheet,
    bool? isLogoutLoading,
    bool? navigateToLogin,
    bool clearError = false,
    bool clearSnackBar = false,
    bool clearEditingContact = false,
    bool clearDeleteOtpSendTo = false,
    bool clearDeleteResendOtpRequest = false,
  }) {
    return SettingsState(
      entity: entity ?? this.entity,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      snackBarMessage: clearSnackBar ? null : (snackBarMessage ?? this.snackBarMessage),
      appVersion: appVersion ?? this.appVersion,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      showThemeBottomSheet: showThemeBottomSheet ?? this.showThemeBottomSheet,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      languageList: languageList ?? this.languageList,
      showLanguageBottomSheet: showLanguageBottomSheet ?? this.showLanguageBottomSheet,
      isLanguageLoading: isLanguageLoading ?? this.isLanguageLoading,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      showAddContactBottomSheet: showAddContactBottomSheet ?? this.showAddContactBottomSheet,
      isContactLoading: isContactLoading ?? this.isContactLoading,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactCountryCode: contactCountryCode ?? this.contactCountryCode,
      editingContactId: clearEditingContact ? null : (editingContactId ?? this.editingContactId),
      countries: countries ?? this.countries,
      multiplePhoneCodeCountryList: multiplePhoneCodeCountryList ?? this.multiplePhoneCodeCountryList,
      showContactCountryPhoneCodeBottomSheet: showContactCountryPhoneCodeBottomSheet ?? this.showContactCountryPhoneCodeBottomSheet,
      showDeleteAccountBottomSheet: showDeleteAccountBottomSheet ?? this.showDeleteAccountBottomSheet,
      showAuthOptionsBottomSheet: showAuthOptionsBottomSheet ?? this.showAuthOptionsBottomSheet,
      showVerifyPasswordBottomSheet: showVerifyPasswordBottomSheet ?? this.showVerifyPasswordBottomSheet,
      showDeleteOtpBottomSheet: showDeleteOtpBottomSheet ?? this.showDeleteOtpBottomSheet,
      isDeleteLoading: isDeleteLoading ?? this.isDeleteLoading,
      authOptions: authOptions ?? this.authOptions,
      deletePassword: deletePassword ?? this.deletePassword,
      deleteOtp: deleteOtp ?? this.deleteOtp,
      deleteOtpSendTo: clearDeleteOtpSendTo ? null : (deleteOtpSendTo ?? this.deleteOtpSendTo),
      deleteOtpSentToDisplay: deleteOtpSentToDisplay ?? this.deleteOtpSentToDisplay,
      deleteResendOtpRequest: clearDeleteResendOtpRequest ? null : (deleteResendOtpRequest ?? this.deleteResendOtpRequest),
      showLogoutBottomSheet: showLogoutBottomSheet ?? this.showLogoutBottomSheet,
      isLogoutLoading: isLogoutLoading ?? this.isLogoutLoading,
      navigateToLogin: navigateToLogin ?? this.navigateToLogin,
    );
  }

  String get themeDisplayName {
    switch (selectedTheme) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }
}

/// Language item model for UI
class LanguageItem {
  final String? id;
  final String code;
  final String name;
  final bool isSelected;

  const LanguageItem({
    this.id,
    required this.code,
    required this.name,
    this.isSelected = false,
  });

  LanguageItem copyWith({bool? isSelected}) {
    return LanguageItem(
      id: id,
      code: code,
      name: name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Emergency contact item model for UI
class EmergencyContactItem {
  final String? id;
  final String name;
  final String phone;
  final String? countryPhoneCode;
  final String? image;

  const EmergencyContactItem({
    this.id,
    required this.name,
    required this.phone,
    this.countryPhoneCode,
    this.image,
  });

  factory EmergencyContactItem.fromApiModel(api.EmergencyContact contact) {
    return EmergencyContactItem(
      id: contact.id,
      name: contact.name ?? '',
      phone: contact.phone ?? '',
      countryPhoneCode: contact.countryPhoneCode,
      image: contact.image,
    );
  }
}

/// Settings ViewModel
class SettingsViewModel extends StateNotifier<SettingsState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;
  final SocketManager _socketManager;

  SettingsViewModel(
    this._appRepository,
    this._sharedPref,
    this._socketManager,
  ) : super(const SettingsState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final entity = _sharedPref.getEntity();
    final theme = _sharedPref.getTheme();
    final themeMode = _parseThemeMode(theme);

    state = state.copyWith(
      entity: entity,
      selectedTheme: themeMode,
      contactCountryCode: entity?.countryPhoneCode ?? '',
    );

    _loadLanguages();
    _loadEmergencyContacts();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final version = await DeviceInfoHelper.getAppVersion();
    state = state.copyWith(appVersion: version);
  }

  AppThemeMode _parseThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  // ============ THEME ============

  void showThemeSelector() {
    state = state.copyWith(showThemeBottomSheet: true);
  }

  void hideThemeSelector() {
    state = state.copyWith(showThemeBottomSheet: false);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final themeString = mode == AppThemeMode.light
        ? 'light'
        : mode == AppThemeMode.dark
            ? 'dark'
            : 'system';

    await _sharedPref.setTheme(themeString);
    state = state.copyWith(
      selectedTheme: mode,
      showThemeBottomSheet: false,
    );
  }

  // ============ LANGUAGE ============

  void showLanguageSelector() {
    state = state.copyWith(showLanguageBottomSheet: true);
  }

  void hideLanguageSelector() {
    state = state.copyWith(showLanguageBottomSheet: false);
  }

  Future<void> _loadLanguages() async {
    final response = await _appRepository.getLanguages();

    switch (response) {
      case Success():
        final languages = response.data ?? [];
        final currentLang = _sharedPref.getLanguage();

        final languageItems = languages.map((lang) {
          return LanguageItem(
            id: lang.id,
            code: lang.code ?? 'en',
            name: lang.name ?? 'Unknown',
            isSelected: lang.code == currentLang,
          );
        }).toList();

        // If no language is selected, select the first one
        if (languageItems.isNotEmpty && !languageItems.any((l) => l.isSelected)) {
          languageItems[0] = languageItems[0].copyWith(isSelected: true);
        }

        final selectedLang = languageItems.firstWhere(
          (l) => l.isSelected,
          orElse: () => languageItems.isNotEmpty
              ? languageItems.first
              : const LanguageItem(code: 'en', name: 'English'),
        );

        state = state.copyWith(
          languageList: languageItems,
          selectedLanguage: selectedLang.name,
        );

      case Error():
        // Fallback to default language
        state = state.copyWith(
          languageList: [const LanguageItem(code: 'en', name: 'English', isSelected: true)],
          selectedLanguage: 'English',
        );

      case Loading():
        break;
    }
  }

  void selectLanguage(int index) {
    final updatedList = state.languageList.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: entry.key == index);
    }).toList();

    state = state.copyWith(languageList: updatedList);
  }

  Future<void> applyLanguage() async {
    final selectedLang = state.languageList.firstWhere(
      (l) => l.isSelected,
      orElse: () => state.languageList.first,
    );

    if (selectedLang.code == _sharedPref.getLanguage()) {
      state = state.copyWith(showLanguageBottomSheet: false);
      return;
    }

    state = state.copyWith(isLanguageLoading: true);

    final request = SetLanguageRequest(language: selectedLang.code);
    final response = await _appRepository.setLanguage(request);

    switch (response) {
      case Success():
        await _sharedPref.setLanguage(selectedLang.code);
        // Fetch new language strings
        await _getLanguageStrings(selectedLang.code);
        state = state.copyWith(
          isLanguageLoading: false,
          showLanguageBottomSheet: false,
          selectedLanguage: selectedLang.name,
        );
        _showSnackBar('Language changed to ${selectedLang.name}');

      case Error():
        state = state.copyWith(isLanguageLoading: false);
        _showSnackBar(response.message ?? 'Failed to change language');

      case Loading():
        break;
    }
  }

  Future<void> _getLanguageStrings(String languageCode) async {
    final response = await _appRepository.getLanguageStrings(languageCode);

    switch (response) {
      case Success():
        if (response.data != null) {
          appStr.updateFromJson(response.data!);
        }
      case Error():
      case Loading():
        // Silently fail - will use existing strings
        break;
    }
  }

  // ============ EMERGENCY CONTACTS ============

  Future<void> _loadEmergencyContacts() async {
    final response = await _appRepository.getEmergencyContacts();

    switch (response) {
      case Success():
        final contacts = response.data?.emergencyContacts ?? [];
        final contactItems = contacts.map((c) => EmergencyContactItem.fromApiModel(c)).toList();
        state = state.copyWith(emergencyContacts: contactItems);

      case Error():
        state = state.copyWith(emergencyContacts: []);

      case Loading():
        break;
    }
  }

  void showAddContactSheet({EmergencyContactItem? contact}) {
    state = state.copyWith(
      showAddContactBottomSheet: true,
      contactName: contact?.name ?? '',
      contactPhone: contact?.phone ?? '',
      contactCountryCode: contact?.countryPhoneCode ?? state.entity?.countryPhoneCode ?? '',
      editingContactId: contact?.id,
    );
    getCountries();
  }

  void hideAddContactSheet() {
    state = state.copyWith(
      showAddContactBottomSheet: false,
      contactName: '',
      contactPhone: '',
      clearEditingContact: true,
    );
  }

  void updateContactName(String name) {
    state = state.copyWith(contactName: name);
  }

  void updateContactPhone(String phone) {
    state = state.copyWith(contactPhone: phone);
  }

  void updateContactCountryCode(String code) {
    state = state.copyWith(contactCountryCode: code);
  }

  Future<void> getCountries() async {
    if (state.countries.isNotEmpty) {
      debugPrint('📞 getCountries: already loaded (${state.countries.length})');
      return;
    }
    debugPrint('📞 getCountries: fetching...');
    final response = await _appRepository.getCountries();
    if (response case Success(data: final d)) {
      final list = d?.countries ?? [];
      debugPrint('📞 getCountries: loaded ${list.length} countries');
      state = state.copyWith(countries: list);
    } else {
      debugPrint('📞 getCountries: FAILED – $response');
    }
  }

  Future<void> toggleContactCountryPhoneCodeBottomSheet() async {
    debugPrint('📞 toggleContactCountryPhoneCodeBottomSheet: start');
    await getCountries();
    debugPrint('📞 countries in state: ${state.countries.length}');

    final entity = _sharedPref.getEntity();
    debugPrint('📞 entity.countryId: ${entity?.countryId}, countryCode: ${entity?.countryCode}, phoneCode: ${entity?.countryPhoneCode}');

    // Countries from this API have no _id — match by ISO code or phone code
    Country? country;
    if (entity?.countryCode != null) {
      country = state.countries.where((c) =>
        c.code == entity!.countryCode || c.alpha2 == entity.countryCode
      ).firstOrNull;
    }
    if (country == null && entity?.countryPhoneCode != null) {
      country = state.countries.where((c) =>
        c.phoneCodes?.contains(entity!.countryPhoneCode) == true
      ).firstOrNull;
    }
    debugPrint('📞 matched country: ${country?.name}, phoneCodes: ${country?.phoneCodes}');

    final phoneCodes = country?.phoneCodes;
    if (country == null || phoneCodes == null || phoneCodes.isEmpty) {
      debugPrint('📞 EARLY RETURN: no phoneCodes found');
      return;
    }
    final c = country; // non-nullable alias for use inside closure

    final list = phoneCodes
        .map((code) => Country(
              id: c.id,
              name: c.name,
              phoneCodes: [code],
              phoneCode: code,
              currencyCode: c.currencyCode,
              currencySign: c.currencySign,
              alpha2: c.alpha2,
              code: c.code,
              code2: c.code2,
              timezones: c.timezones,
              isBusiness: c.isBusiness,
            ))
        .toList();

    debugPrint('📞 multiplePhoneCodeCountryList: ${list.length} codes → ${list.map((c) => c.phoneCodes?.first)}');
    state = state.copyWith(
      multiplePhoneCodeCountryList: list,
      showContactCountryPhoneCodeBottomSheet: true,
    );
  }

  void dismissContactCountryPhoneCodeBottomSheet() {
    state = state.copyWith(showContactCountryPhoneCodeBottomSheet: false);
  }

  void updateContactCountryPhoneCode(Country country) {
    state = state.copyWith(
      contactCountryCode: country.phoneCodes?.firstOrNull ?? '',
    );
  }

  bool _validateEmergencyContact() {
    // 1. Name must not be empty
    if (state.contactName.isEmpty) {
      _showSnackBar(getString(null, 'error_please_enter_name'));
      return false;
    }

    // 2. Country phone code must be selected
    if (state.contactCountryCode.trim().isEmpty) {
      _showSnackBar(getString(null, 'error_please_select_country_phone_code'));
      return false;
    }

    // 3. Phone number must not be empty
    if (state.contactPhone.trim().isEmpty) {
      _showSnackBar(getString(appStr.errorPleaseEnterPhoneNumber, 'error_please_enter_phone_number'));
      return false;
    }

    // 4. Phone format: 6–12 digits, all numeric
    final phone = state.contactPhone.trim();
    final isValidFormat = phone.length >= 6 &&
        phone.length <= 12 &&
        phone.codeUnits.every((c) => c >= 48 && c <= 57);
    if (!isValidFormat) {
      _showSnackBar(getString(appStr.errorPleaseEnterValidPhoneNumber, 'error_please_enter_valid_phone_number'));
      return false;
    }

    // 5. Phone must not be the user's own phone number
    final ownPhone = state.entity?.phone ?? '';
    if (ownPhone.isNotEmpty && phone == ownPhone) {
      _showSnackBar(getString(appStr.errorPleaseEnterValidPhoneNumber, 'error_please_enter_valid_phone_number'));
      return false;
    }

    return true;
  }

  Future<void> saveEmergencyContact() async {
    if (!_validateEmergencyContact()) return;
    state = state.copyWith(isContactLoading: true);

    final request = EmergencyContactRequest(
      name: state.contactName,
      phone: state.contactPhone,
      countryPhoneCode: state.contactCountryCode,
    );

    final isEditing = state.editingContactId != null;

    final response = isEditing
        ? await _appRepository.updateEmergencyContact(state.editingContactId!, request)
        : await _appRepository.addEmergencyContact(request);

    switch (response) {
      case Success():
        state = state.copyWith(
          isContactLoading: false,
          showAddContactBottomSheet: false,
          contactName: '',
          contactPhone: '',
          clearEditingContact: true,
        );
        _showSnackBar(isEditing ? 'Contact updated' : 'Contact added');
        // Re-fetch contacts list since add/update response doesn't include the list
        await _loadEmergencyContacts();

      case Error():
        state = state.copyWith(isContactLoading: false);
        _showSnackBar(response.message ?? 'Failed to save contact');

      case Loading():
        break;
    }
  }

  Future<void> deleteEmergencyContact(int index) async {
    if (index < 0 || index >= state.emergencyContacts.length) return;

    final contact = state.emergencyContacts[index];
    if (contact.id == null) return;

    state = state.copyWith(isLoading: true);

    final response = await _appRepository.deleteEmergencyContact(contact.id!);

    switch (response) {
      case Success():
        state = state.copyWith(isLoading: false);
        _showSnackBar('Contact removed');
        // Re-fetch contacts list since delete response doesn't include the list
        await _loadEmergencyContacts();

      case Error():
        state = state.copyWith(isLoading: false);
        _showSnackBar(response.message ?? 'Failed to delete contact');

      case Loading():
        break;
    }
  }

  // ============ DELETE ACCOUNT ============

  void showDeleteAccountConfirmation() {
    state = state.copyWith(showDeleteAccountBottomSheet: true);
  }

  void hideDeleteAccountConfirmation() {
    state = state.copyWith(showDeleteAccountBottomSheet: false);
  }

  /// Called when user taps "Yes Delete" on confirmation sheet
  void onYesDeleteAccountClick() {
    state = state.copyWith(showDeleteAccountBottomSheet: false);

    final entity = state.entity;
    // Social logins (Google/Apple) don't need verification
    if (entity?.isSocialAccount == true ||
        entity?.loginBy == constants.LoginBy.google ||
        entity?.loginBy == constants.LoginBy.apple) {
      _deleteAccount({});
      return;
    }

    // Build auth options from entitySetting.deleteBy
    final deleteBy = _sharedPref.getSetting()?.entitySetting?.deleteBy ?? [];
    final options = <DeleteAuthOption>[];

    if (deleteBy.contains(constants.LoginBy.password)) {
      options.add(DeleteAuthOption(
        label: getString(appStr.descriptionPassword, 'description_password'),
      ));
    }
    if (deleteBy.contains(constants.LoginBy.otp)) {
      final email = entity?.email;
      final phone = entity?.phone;
      final code = entity?.countryPhoneCode ?? '';
      if (email != null && email.isNotEmpty) {
        options.add(DeleteAuthOption(
          label: email,
          sendMode: constants.OtpSendMode.email,
        ));
      }
      if (phone != null && phone.isNotEmpty) {
        options.add(DeleteAuthOption(
          label: '$code $phone'.trim(),
          sendMode: constants.OtpSendMode.sms,
        ));
      }
    }

    if (options.isEmpty) {
      // No specific verification required
      _deleteAccount({});
      return;
    }

    // Pre-select the first option
    final selected = options
        .asMap()
        .map((i, o) => MapEntry(i, o.copyWith(isSelected: i == 0)))
        .values
        .toList();

    state = state.copyWith(
      authOptions: selected,
      showAuthOptionsBottomSheet: true,
    );
  }

  void selectAuthOption(int index) {
    final updated = state.authOptions
        .asMap()
        .map((i, o) => MapEntry(i, o.copyWith(isSelected: i == index)))
        .values
        .toList();
    state = state.copyWith(authOptions: updated);
  }

  void dismissAuthOptions() {
    state = state.copyWith(showAuthOptionsBottomSheet: false);
  }

  void confirmAuthOption() {
    final selected = state.authOptions.where((o) => o.isSelected).firstOrNull;
    if (selected == null) return;

    state = state.copyWith(showAuthOptionsBottomSheet: false);

    if (selected.sendMode == null) {
      // Password path
      state = state.copyWith(
        deletePassword: '',
        showVerifyPasswordBottomSheet: true,
      );
    } else {
      // OTP path
      _generateDeleteOtp(selected);
    }
  }

  // ─── Password path ────────────────────────────────────────────────────────

  void updateDeletePassword(String value) {
    state = state.copyWith(deletePassword: value);
  }

  void dismissVerifyPassword() {
    state = state.copyWith(showVerifyPasswordBottomSheet: false, deletePassword: '');
  }

  void submitVerifyPassword() {
    if (state.deletePassword.trim().isEmpty) {
      _showSnackBar(getString(appStr.errorPleaseEnterPassword, 'error_please_enter_password'));
      return;
    }
    state = state.copyWith(showVerifyPasswordBottomSheet: false);
    _deleteAccount({'password': state.deletePassword});
  }

  // ─── OTP path ─────────────────────────────────────────────────────────────

  Future<void> _generateDeleteOtp(DeleteAuthOption option) async {
    final entity = state.entity;
    final request = option.sendMode == constants.OtpSendMode.email
        ? GenerateOtpRequest(
            sendTo: constants.OtpSendMode.email,
            email: entity?.email,
          )
        : GenerateOtpRequest(
            sendTo: constants.OtpSendMode.sms,
            phone: entity?.phone,
            countryPhoneCode: entity?.countryPhoneCode,
          );

    state = state.copyWith(isDeleteLoading: true);
    final response = await _appRepository.generateOtp(request);
    state = state.copyWith(isDeleteLoading: false);

    switch (response) {
      case Success():
        _showSnackBar(response.message ?? '');
        state = state.copyWith(
          deleteOtp: '',
          deleteOtpSendTo: option.sendMode,
          deleteOtpSentToDisplay: option.label,
          deleteResendOtpRequest: request,
          showDeleteOtpBottomSheet: true,
        );

      case Error():
        _showSnackBar(response.message ?? 'Failed to send OTP');

      case Loading():
        break;
    }
  }

  void updateDeleteOtp(String value) {
    state = state.copyWith(deleteOtp: value);
  }

  void dismissDeleteOtp() {
    state = state.copyWith(
      showDeleteOtpBottomSheet: false,
      deleteOtp: '',
      clearDeleteResendOtpRequest: true,
    );
  }

  Future<void> resendDeleteOtp() async {
    final request = state.deleteResendOtpRequest;
    if (request == null) return;
    state = state.copyWith(isDeleteLoading: true);
    final response = await _appRepository.generateOtp(request);
    state = state.copyWith(isDeleteLoading: false);
    switch (response) {
      case Success():
        _showSnackBar(response.message ?? '');
        state = state.copyWith(deleteOtp: '');
      case Error():
        _showSnackBar(response.message ?? 'Failed to resend OTP');
      case Loading():
        break;
    }
  }

  Future<void> submitDeleteOtp() async {
    if (state.deleteOtp.trim().isEmpty) {
      _showSnackBar(getString(appStr.errorPleaseEnterOtp, 'error_please_enter_otp'));
      return;
    }
    final entity = state.entity;
    final request = VerifyOtpRequest(
      sendTo: state.deleteOtpSendTo,
      phone: entity?.phone,
      countryPhoneCode: entity?.countryPhoneCode,
      email: entity?.email,
      enteredOTP: state.deleteOtp,
    );
    state = state.copyWith(isDeleteLoading: true);
    final response = await _appRepository.verifyOtp(request);
    state = state.copyWith(isDeleteLoading: false);

    switch (response) {
      case Success():
        state = state.copyWith(showDeleteOtpBottomSheet: false);
        _deleteAccount({'verificationToken': response.data?.verificationToken ?? ''});

      case Error():
        _showSnackBar(response.message ?? 'Invalid OTP');

      case Loading():
        break;
    }
  }

  // ─── API call ─────────────────────────────────────────────────────────────

  Future<void> _deleteAccount(Map<String, String> body) async {
    state = state.copyWith(isDeleteLoading: true);
    final response = await _appRepository.deleteAccount(body);

    switch (response) {
      case Success():
        await NotificationManager.instance.unsubscribeFromCurrentTopic();
        await NotificationManager.instance.cancelAllNotifications();
        await LiveActivityManager.instance.stopAllActivities();
        NotificationManager.instance.onTokenRefreshed = null;
        NotificationManager.instance.onNotificationTapped = null;
        _socketManager.offAllEvents();
        _socketManager.disconnect();
        await _sharedPref.signOut();
        state = state.copyWith(
          isDeleteLoading: false,
          showDeleteAccountBottomSheet: false,
          navigateToLogin: true,
        );

      case Error():
        state = state.copyWith(isDeleteLoading: false);
        _showSnackBar(response.message ?? 'Failed to delete account');

      case Loading():
        break;
    }
  }

  // ============ LOGOUT ============

  void showLogoutConfirmation() {
    state = state.copyWith(showLogoutBottomSheet: true);
  }

  void hideLogoutConfirmation() {
    state = state.copyWith(showLogoutBottomSheet: false);
  }

  Future<void> logout() async {
    state = state.copyWith(isLogoutLoading: true);

    final response = await _appRepository.signOut();

    switch (response) {
      case Success():
        // Cleanup: unsubscribe topic, cancel notifications, stop live activities, disconnect socket
        await NotificationManager.instance.unsubscribeFromCurrentTopic();
        await NotificationManager.instance.cancelAllNotifications();
        await LiveActivityManager.instance.stopAllActivities();
        NotificationManager.instance.onTokenRefreshed = null;
        NotificationManager.instance.onNotificationTapped = null;
        _socketManager.offAllEvents();
        _socketManager.disconnect();
        await _sharedPref.signOut();
        state = state.copyWith(
          isLogoutLoading: false,
          showLogoutBottomSheet: false,
          navigateToLogin: true,
        );

      case Error():
        state = state.copyWith(isLogoutLoading: false);
        _showSnackBar(response.message ?? 'Logout failed');

      case Loading():
        break;
    }
  }

  // ============ HELPERS ============

  void _showSnackBar(String message) {
    state = state.copyWith(snackBarMessage: message);
  }

  void clearSnackBar() {
    state = state.copyWith(clearSnackBar: true);
  }

  void clearNavigationFlag() {
    state = state.copyWith(navigateToLogin: false);
  }

  void refreshUserData() {
    final entity = _sharedPref.getEntity();
    state = state.copyWith(entity: entity);
  }
}

/// Provider for SettingsViewModel
final settingsViewModelProvider =
    StateNotifierProvider.autoDispose<SettingsViewModel, SettingsState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );

  final socketManager = ref.read(socketManagerProvider);

  return SettingsViewModel(appRepository, sharedPref, socketManager);
});
