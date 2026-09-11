import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/app_repository.dart';
import '../data/api/response_state.dart';
import '../models/requests/entity_detail_request.dart';
import '../models/requests/generate_otp_request.dart';
import '../models/requests/update_profile_request.dart';
import '../models/responses/auth/country_response.dart';
import '../models/responses/auth/entity_detail_response.dart';
import '../core/constants/app_constants.dart' as constants;
import '../core/providers/app_providers.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/utils/validator/validator.dart';
import '../core/localization/app_strings.dart';
import '../core/utils/parse_response.dart';

/// Edit profile field type
enum EditProfileField { name, gender, phone, email }

/// Edit profile step for fields requiring verification
enum EditProfileStep { input, otp }

class EditProfileState {
  final bool isLoading;
  final String? error;
  final EditProfileField field;
  final EditProfileStep step;

  // Name fields
  final String firstName;
  final String lastName;
  final String? firstNameError;
  final String? lastNameError;

  // Gender field
  final constants.Gender selectedGender;

  // Phone fields
  final String phoneNumber;
  final String countryPhoneCode;
  final String? phoneError;

  // Email field
  final String email;
  final String? emailError;

  // OTP fields
  final String otp;
  final int otpLength;
  final int resendSeconds;

  // Country picker
  final List<Country> countries;
  final Country? selectedCountry;

  // Verification flags
  final bool isPhoneVerificationEnabled;
  final bool isEmailVerificationEnabled;

  // Success flag
  final bool isUpdateSuccess;

  // Original values (to check if changed)
  final String originalFirstName;
  final String originalLastName;
  final constants.Gender originalGender;
  final String originalPhoneNumber;
  final String originalEmail;

  EditProfileState({
    this.isLoading = false,
    this.error,
    this.field = EditProfileField.name,
    this.step = EditProfileStep.input,
    this.firstName = '',
    this.lastName = '',
    this.firstNameError,
    this.lastNameError,
    this.selectedGender = constants.Gender.none,
    this.phoneNumber = '',
    this.countryPhoneCode = '',
    this.phoneError,
    this.email = '',
    this.emailError,
    this.otp = '',
    this.otpLength = 6,
    this.resendSeconds = 0,
    this.countries = const [],
    this.selectedCountry,
    this.isPhoneVerificationEnabled = false,
    this.isEmailVerificationEnabled = false,
    this.isUpdateSuccess = false,
    this.originalFirstName = '',
    this.originalLastName = '',
    this.originalGender = constants.Gender.none,
    this.originalPhoneNumber = '',
    this.originalEmail = '',
  });

  bool get isFirstNameValid => firstName.isNotEmpty;
  bool get isLastNameValid => lastName.isNotEmpty;
  bool get isNameValid => isFirstNameValid && isLastNameValid;
  bool get isPhoneValid => phoneNumber.isNotEmpty && phoneNumber.length >= 6;
  bool get isEmailValid {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool get isOtpComplete => otp.length == otpLength;

  bool get hasNameChanged =>
      firstName != originalFirstName || lastName != originalLastName;
  bool get hasGenderChanged => selectedGender != originalGender;
  bool get hasPhoneChanged => phoneNumber != originalPhoneNumber;
  bool get hasEmailChanged => email != originalEmail;

  bool get canProceed {
    switch (field) {
      case EditProfileField.name:
        return isNameValid && hasNameChanged;
      case EditProfileField.gender:
        return hasGenderChanged;
      case EditProfileField.phone:
        if (step == EditProfileStep.otp) {
          return isOtpComplete;
        }
        return isPhoneValid && hasPhoneChanged;
      case EditProfileField.email:
        if (step == EditProfileStep.otp) {
          return isOtpComplete;
        }
        return isEmailValid && hasEmailChanged;
    }
  }

  EditProfileState copyWith({
    bool? isLoading,
    String? error,
    EditProfileField? field,
    EditProfileStep? step,
    String? firstName,
    String? lastName,
    String? firstNameError,
    String? lastNameError,
    constants.Gender? selectedGender,
    String? phoneNumber,
    String? countryPhoneCode,
    String? phoneError,
    String? email,
    String? emailError,
    String? otp,
    int? otpLength,
    int? resendSeconds,
    List<Country>? countries,
    Country? Function()? selectedCountry,
    bool? isPhoneVerificationEnabled,
    bool? isEmailVerificationEnabled,
    bool? isUpdateSuccess,
    String? originalFirstName,
    String? originalLastName,
    constants.Gender? originalGender,
    String? originalPhoneNumber,
    String? originalEmail,
    bool clearError = false,
    bool clearFirstNameError = false,
    bool clearLastNameError = false,
    bool clearPhoneError = false,
    bool clearEmailError = false,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      field: field ?? this.field,
      step: step ?? this.step,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      firstNameError:
          clearFirstNameError ? null : (firstNameError ?? this.firstNameError),
      lastNameError:
          clearLastNameError ? null : (lastNameError ?? this.lastNameError),
      selectedGender: selectedGender ?? this.selectedGender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryPhoneCode: countryPhoneCode ?? this.countryPhoneCode,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      email: email ?? this.email,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      otp: otp ?? this.otp,
      otpLength: otpLength ?? this.otpLength,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      countries: countries ?? this.countries,
      selectedCountry: selectedCountry != null ? selectedCountry() : this.selectedCountry,
      isPhoneVerificationEnabled:
          isPhoneVerificationEnabled ?? this.isPhoneVerificationEnabled,
      isEmailVerificationEnabled:
          isEmailVerificationEnabled ?? this.isEmailVerificationEnabled,
      isUpdateSuccess: isUpdateSuccess ?? this.isUpdateSuccess,
      originalFirstName: originalFirstName ?? this.originalFirstName,
      originalLastName: originalLastName ?? this.originalLastName,
      originalGender: originalGender ?? this.originalGender,
      originalPhoneNumber: originalPhoneNumber ?? this.originalPhoneNumber,
      originalEmail: originalEmail ?? this.originalEmail,
    );
  }
}

class EditProfileViewModel extends StateNotifier<EditProfileState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;

  EditProfileViewModel(this._appRepository, this._sharedPref)
      : super(EditProfileState());

  /// Initialize for editing a specific field
  void init(EditProfileField field) {
    final entity = _sharedPref.getEntity();
    final setting = _sharedPref.getSetting();

    final firstName = entity?.firstName ?? '';
    final lastName = entity?.lastName ?? '';
    final gender = constants.Gender.fromValue(entity?.gender);
    final phone = entity?.phone ?? '';
    final countryPhoneCode = entity?.countryPhoneCode ?? '';
    final email = entity?.email ?? '';

    // Get verification flags
    final isVerification = setting?.entitySetting?.isVerification ?? [];
    final isPhoneVerification = isVerification.contains(constants.LoginBy.phone);
    final isEmailVerification = isVerification.contains(constants.LoginBy.email);

    state = EditProfileState(
      field: field,
      step: EditProfileStep.input,
      firstName: firstName,
      lastName: lastName,
      selectedGender: gender,
      phoneNumber: phone,
      countryPhoneCode: countryPhoneCode,
      email: email,
      isPhoneVerificationEnabled: isPhoneVerification,
      isEmailVerificationEnabled: isEmailVerification,
      originalFirstName: firstName,
      originalLastName: lastName,
      originalGender: gender,
      originalPhoneNumber: phone,
      originalEmail: email,
    );

    // Fetch countries for phone field picker
    if (field == EditProfileField.phone) {
      _fetchCountries(countryPhoneCode);
    }
  }

  Future<void> _fetchCountries(String currentPhoneCode) async {
    final response = await _appRepository.getCountries();

    switch (response) {
      case Success<CountryResponse>():
        final countries = response.data?.countries ?? [];
        // Try to find the country matching current phone code
        Country? matched;
        if (currentPhoneCode.isNotEmpty && countries.isNotEmpty) {
          matched = countries.cast<Country?>().firstWhere(
            (c) => c?.displayPhoneCode == currentPhoneCode,
            orElse: () => null,
          );
        }
        state = state.copyWith(
          countries: countries,
          selectedCountry: () => matched,
        );
      case Error():
      case Loading():
        break;
    }
  }

  void setSelectedCountry(Country country) {
    state = state.copyWith(
      selectedCountry: () => country,
      countryPhoneCode: country.displayPhoneCode,
      clearError: true,
    );
  }

  // Setters
  void setFirstName(String value) {
    state = state.copyWith(
        firstName: value, clearFirstNameError: true, clearError: true);
  }

  void setLastName(String value) {
    state = state.copyWith(
        lastName: value, clearLastNameError: true, clearError: true);
  }

  void setGender(constants.Gender gender) {
    state = state.copyWith(selectedGender: gender, clearError: true);
  }

  void setPhoneNumber(String value) {
    state =
        state.copyWith(phoneNumber: value, clearPhoneError: true, clearError: true);
  }

  void setEmail(String value) {
    state =
        state.copyWith(email: value, clearEmailError: true, clearError: true);
  }

  void setOtp(String value) {
    state = state.copyWith(otp: value, clearError: true);
  }

  void updateResendSeconds(int seconds) {
    state = state.copyWith(resendSeconds: seconds);
  }

  void goBack() {
    if (state.step == EditProfileStep.otp) {
      state = state.copyWith(step: EditProfileStep.input, otp: '', clearError: true);
    }
  }

  /// Validate and proceed
  Future<bool> validateAndProceed() async {
    switch (state.field) {
      case EditProfileField.name:
        return await _updateName();
      case EditProfileField.gender:
        return await _updateGender();
      case EditProfileField.phone:
        return await _handlePhoneUpdate();
      case EditProfileField.email:
        return await _handleEmailUpdate();
    }
  }

  Future<bool> _updateName() async {
    if (!Validator.validFirstName(state.firstName).status) {
      state = state.copyWith(
        firstNameError: getString(
            appStr.errorPleaseEnterValidFirstName, 'error_please_enter_valid_first_name'),
      );
      return false;
    }

    if (!Validator.validLastName(state.lastName).status) {
      state = state.copyWith(
        lastNameError: getString(
            appStr.errorPleaseEnterValidLastName, 'error_please_enter_valid_last_name'),
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    return await _callUpdateProfile(_buildUpdateProfileRequest());
  }

  Future<bool> _updateGender() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final request = UpdateProfileRequest(
      gender: state.selectedGender.value,
    );

    return await _callUpdateProfile(request);
  }

  Future<bool> _handlePhoneUpdate() async {
    if (state.step == EditProfileStep.input) {
      // Validate phone
      if (!Validator.validPhoneNumber(state.phoneNumber).status) {
        state = state.copyWith(
          phoneError: getString(
              appStr.errorPleaseEnterPhoneNumber, 'error_please_enter_phone_number'),
        );
        return false;
      }

      if (!Validator.validPhoneNumberFormatForLogin(state.phoneNumber).status) {
        state = state.copyWith(
          phoneError: getString(appStr.errorPleaseEnterValidPhoneNumber,
              'error_please_enter_valid_phone_number'),
        );
        return false;
      }

      // Check if verification is required
      if (state.isPhoneVerificationEnabled) {
        // Generate OTP and go to OTP step
        final otpSent = await _generatePhoneOtp();
        if (otpSent) {
          state = state.copyWith(step: EditProfileStep.otp);
          return true;
        }
        return false;
      } else {
        // No verification, directly update
        return await _updatePhoneDirectly();
      }
    } else {
      // OTP step - verify and update
      return await _updatePhoneWithOtp();
    }
  }

  Future<bool> _handleEmailUpdate() async {
    if (state.step == EditProfileStep.input) {
      // Validate email
      if (!Validator.validEmail(state.email).status) {
        state = state.copyWith(
          emailError:
              getString(appStr.errorPleaseEnterEmail, 'error_please_enter_email'),
        );
        return false;
      }

      if (!Validator.validEmailFormat(state.email).status) {
        state = state.copyWith(
          emailError: getString(
              appStr.errorPleaseEnterValidEmail, 'error_please_enter_valid_email'),
        );
        return false;
      }

      // Check if verification is required
      if (state.isEmailVerificationEnabled) {
        // Generate OTP and go to OTP step
        final otpSent = await _generateEmailOtp();
        if (otpSent) {
          state = state.copyWith(step: EditProfileStep.otp);
          return true;
        }
        return false;
      } else {
        // No verification, directly update
        return await _updateEmailDirectly();
      }
    } else {
      // OTP step - verify and update
      return await _updateEmailWithOtp();
    }
  }

  Future<bool> _generatePhoneOtp() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final request = GenerateOtpRequest(
      sendTo: constants.OtpSendMode.sms,
      countryPhoneCode: state.countryPhoneCode,
      phone: state.phoneNumber,
    );

    final response = await _appRepository.generateOtp(request);

    switch (response) {
      case Success():
        state = state.copyWith(isLoading: false);
        return true;
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Failed to send OTP',
        );
        return false;
      case Loading():
        return false;
    }
  }

  Future<bool> _generateEmailOtp() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final request = GenerateOtpRequest(
      sendTo: constants.OtpSendMode.email,
      email: state.email,
    );

    final response = await _appRepository.generateOtp(request);

    switch (response) {
      case Success():
        state = state.copyWith(isLoading: false);
        return true;
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Failed to send OTP',
        );
        return false;
      case Loading():
        return false;
    }
  }

  Future<bool> resendOtp() async {
    if (state.resendSeconds > 0) return false;

    if (state.field == EditProfileField.phone) {
      return await _generatePhoneOtp();
    } else if (state.field == EditProfileField.email) {
      return await _generateEmailOtp();
    }
    return false;
  }

  Future<bool> _updatePhoneDirectly() async {
    state = state.copyWith(isLoading: true, clearError: true);

    return await _callUpdateProfile(_buildUpdateProfileRequest());
  }

  Future<bool> _updatePhoneWithOtp() async {
    state = state.copyWith(isLoading: true, clearError: true);

    return await _callUpdateProfile(_buildUpdateProfileRequest(
      enteredOTP: state.otp,
      sendTo: constants.OtpSendMode.sms,
    ));
  }

  Future<bool> _updateEmailDirectly() async {
    state = state.copyWith(isLoading: true, clearError: true);

    return await _callUpdateProfile(_buildUpdateProfileRequest());
  }

  Future<bool> _updateEmailWithOtp() async {
    state = state.copyWith(isLoading: true, clearError: true);

    return await _callUpdateProfile(_buildUpdateProfileRequest(
      enteredOTP: state.otp,
      enteredOTPMail: state.otp,
      sendTo: constants.OtpSendMode.email,
    ));
  }

  /// Native sends the **complete** profile payload on every profile-edit
  /// update_profile call (see `ProfileViewModel.updateProfile` in the Android
  /// app). Posting only the changed field makes the server fail and return an
  /// HTML error page instead of JSON, so always send the full set here.
  ///
  /// Gender is deliberately excluded — native updates it with a gender-only
  /// request from its Home/Courier flows, and that path is left as-is.
  UpdateProfileRequest _buildUpdateProfileRequest({
    String enteredOTP = '',
    String enteredOTPMail = '',
    int sendTo = 0,
  }) {
    return UpdateProfileRequest(
      sendTo: sendTo,
      firstName: _orNull(state.firstName),
      lastName: _orNull(state.lastName),
      countryPhoneCode: _orNull(state.countryPhoneCode),
      phone: _orNull(state.phoneNumber),
      email: _orNull(state.email),
      password: '',
      newPassword: '',
      enteredOTP: enteredOTP,
      enteredOTPMail: enteredOTPMail,
    );
  }

  /// Social sign-up accounts have no phone number, so the state holds an empty
  /// string for it. Sending `""` makes the server reject the whole update with
  /// "Phone required", while a missing key is accepted — and `includeIfNull:
  /// false` drops nulls from the JSON. Password/OTP fields keep their empty
  /// strings because native sends those explicitly.
  String? _orNull(String value) => value.trim().isEmpty ? null : value;

  Future<bool> _callUpdateProfile(UpdateProfileRequest request) async {
    final response = await _appRepository.updateProfile(request);

    switch (response) {
      case Success():
        // Refresh entity data
        await _refreshEntityData();
        state = state.copyWith(isLoading: false, isUpdateSuccess: true);
        return true;
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Update failed',
        );
        return false;
      case Loading():
        return false;
    }
  }

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
        }
      case Error():
        // Silently fail - user profile was already updated
        break;
      case Loading():
        break;
    }
  }
}

/// Provider for EditProfileViewModel
final editProfileViewModelProvider =
    StateNotifierProvider.autoDispose<EditProfileViewModel, EditProfileState>(
        (ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  return EditProfileViewModel(appRepository, sharedPref);
});
