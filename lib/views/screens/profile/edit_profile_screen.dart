import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/constants/app_constants.dart' show Gender;
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/string_constants.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/validator/validator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/responses/auth/country_response.dart';
import '../../../viewmodels/edit_profile_viewmodel.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_text_field.dart';
import '../../../views/widgets/app_toolbar.dart';
import '../../../views/widgets/country_picker_dropdown.dart';
import '../../../views/widgets/otp_input_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final EditProfileField field;

  const EditProfileScreen({
    super.key,
    required this.field,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  // Country picker
  final _countryCodeKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  // Timer for resend
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeField();
    });
  }

  void _initializeField() {
    final notifier = ref.read(editProfileViewModelProvider.notifier);
    notifier.init(widget.field);

    // Set initial values to controllers after init
    final state = ref.read(editProfileViewModelProvider);
    _firstNameController.text = state.firstName;
    _lastNameController.text = state.lastName;
    _phoneController.text = state.phoneNumber;
    _emailController.text = state.email;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showCountryPicker(
    List<Country> countries,
    Country? selectedCountry,
    EditProfileViewModel notifier,
  ) {
    _removeOverlay();

    final renderBox =
        _countryCodeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = screenWidth - (AppDimens.padding * 2);

    _overlayEntry = OverlayEntry(
      builder: (context) => CountryPickerOverlay(
        countries: countries,
        selectedCountry: selectedCountry,
        position: Offset(AppDimens.padding, position.dy + size.height + 4),
        width: dropdownWidth,
        onCountrySelected: (country) {
          notifier.setSelectedCountry(country);
          _removeOverlay();
        },
        onDismiss: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _startResendTimer() {
    final notifier = ref.read(editProfileViewModelProvider.notifier);
    notifier.updateResendSeconds(ValidatorConfig.resendOtpTime);

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSeconds = ref.read(editProfileViewModelProvider).resendSeconds;
      if (currentSeconds > 0) {
        notifier.updateResendSeconds(currentSeconds - 1);
      } else {
        timer.cancel();
      }
    });
  }

  String _formattedResendTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Event handlers
  void _onFirstNameChanged(String value) {
    ref.read(editProfileViewModelProvider.notifier).setFirstName(value);
  }

  void _onLastNameChanged(String value) {
    ref.read(editProfileViewModelProvider.notifier).setLastName(value);
  }

  void _onPhoneChanged(String value) {
    ref.read(editProfileViewModelProvider.notifier).setPhoneNumber(value);
  }

  void _onEmailChanged(String value) {
    ref.read(editProfileViewModelProvider.notifier).setEmail(value);
  }

  void _onOtpChanged(String value) {
    ref.read(editProfileViewModelProvider.notifier).setOtp(value);
  }

  void _onGenderSelected(Gender gender) {
    ref.read(editProfileViewModelProvider.notifier).setGender(gender);
  }

  Future<void> _onUpdatePressed() async {
    final state = ref.read(editProfileViewModelProvider);
    final notifier = ref.read(editProfileViewModelProvider.notifier);

    if (!state.canProceed) return;

    FocusScope.of(context).unfocus();

    final success = await notifier.validateAndProceed();

    // If moving to OTP step, start timer
    if (success && state.step == EditProfileStep.input &&
        (state.field == EditProfileField.phone || state.field == EditProfileField.email)) {
      final newState = ref.read(editProfileViewModelProvider);
      if (newState.step == EditProfileStep.otp) {
        _startResendTimer();
      }
    }
  }

  Future<void> _resendOtp() async {
    final state = ref.read(editProfileViewModelProvider);
    if (state.resendSeconds > 0) return;

    final notifier = ref.read(editProfileViewModelProvider.notifier);
    final success = await notifier.resendOtp();
    if (success) {
      _startResendTimer();
    }
  }

  void _onBackPressed() {
    final state = ref.read(editProfileViewModelProvider);
    final notifier = ref.read(editProfileViewModelProvider.notifier);

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).unfocus();
      if (state.step == EditProfileStep.otp) {
        _resendTimer?.cancel();
        _otpController.clear();
        notifier.goBack();
      } else {
        context.goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileViewModelProvider);
    final colors = context.colors;

    // Listen for update success
    ref.listen<EditProfileState>(editProfileViewModelProvider, (previous, next) {
      if (next.isUpdateSuccess && mounted) {
        context.goBack(true); // Return true to indicate success
      }
    });

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppToolbar(
              title: _getAppBarTitle(state),
              onBack: _onBackPressed,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppDimens.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.paddingXL),
                    _buildHeader(state, colors),
                    if (_hasSubtitle(state)) ...[
                      const SizedBox(height: AppDimens.paddingM),
                      _buildSubtitle(state, colors),
                    ],
                    const SizedBox(height: AppDimens.paddingXXL),
                    _buildInputField(state, colors),
                  ],
                ),
              ),
            ),
            _buildBottomBar(state, colors),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(EditProfileState state) {
    switch (state.field) {
      case EditProfileField.name:
        return getString(appStr.headingName, 'heading_name');
      case EditProfileField.gender:
        return getString(appStr.headingGender, 'heading_gender');
      case EditProfileField.phone:
        return getString(appStr.hintPhoneNumber, 'hint_phone_number');
      case EditProfileField.email:
        return getString(appStr.descriptionEmail, 'description_email');
    }
  }

  bool _hasSubtitle(EditProfileState state) {
    return state.field == EditProfileField.name ||
        state.field == EditProfileField.phone ||
        state.field == EditProfileField.email ||
        state.step == EditProfileStep.otp;
  }

  Widget _buildHeader(EditProfileState state, AppColorPalette colors) {
    // For OTP step show a distinct heading ("Verify Account") since it differs from the toolbar title
    if (state.step == EditProfileStep.otp) {
      return AppText.heading(
        getString(appStr.headingVerifyAccount, 'heading_verify_account'),
      );
    }

    // For all input fields the toolbar already shows the title — skip duplicate header
    return const SizedBox.shrink();
  }

  Widget _buildSubtitle(EditProfileState state, AppColorPalette colors) {
    String subtitle;

    if (state.step == EditProfileStep.otp) {
      final target = state.field == EditProfileField.phone
          ? state.phoneNumber
          : state.email;
      subtitle = getString(appStr.descriptionEnterOtpSentTo, 'description_enter_otp_sent_to')
          .replacePlaceholders({
            StringConstant.leftParam: state.otpLength.toString(),
            StringConstant.rightParam: target,
          });
    } else {
      switch (state.field) {
        case EditProfileField.name:
          subtitle = getString(appStr.descriptionProfileName, 'description_profile_name');
          break;
        case EditProfileField.phone:
          subtitle = getString(appStr.descriptionYouWillUseThisNumber,
              'description_you_will_use_this_number');
          break;
        case EditProfileField.email:
          subtitle = getString(appStr.descriptionYouWillUseThisEmail,
              'description_you_will_use_this_email');
          break;
        default:
          return const SizedBox.shrink();
      }
    }

    return AppText.body(
      subtitle,
      color: colors.colorText,
    );
  }

  Widget _buildInputField(EditProfileState state, AppColorPalette colors) {
    if (state.step == EditProfileStep.otp) {
      return _buildOtpInput(state, colors);
    }

    switch (state.field) {
      case EditProfileField.name:
        return _buildNameInput(state, colors);
      case EditProfileField.gender:
        return _buildGenderInput(state, colors);
      case EditProfileField.phone:
        return _buildPhoneInput(state, colors);
      case EditProfileField.email:
        return _buildEmailInput(state, colors);
    }
  }

  Widget _buildNameInput(EditProfileState state, AppColorPalette colors) {
    final firstNameString = getString(appStr.hintFirstName, 'hint_first_name');
    final lastNameString = getString(appStr.hintLastName, 'hint_last_name');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(firstNameString, fontWeight: FontWeight.w500),
        const SizedBox(height: AppDimens.paddingS),
        AppTextField(
          controller: _firstNameController,
          hintText: firstNameString,
          onChanged: _onFirstNameChanged,
        ),
        if (state.firstNameError != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.firstNameError!,
            color: colors.colorWarning,
          ),
        ],
        const SizedBox(height: AppDimens.paddingL),
        AppText.body(lastNameString, fontWeight: FontWeight.w500),
        const SizedBox(height: AppDimens.paddingS),
        AppTextField(
          controller: _lastNameController,
          hintText: lastNameString,
          onChanged: _onLastNameChanged,
        ),
        if (state.lastNameError != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.lastNameError!,
            color: colors.colorWarning,
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: AppDimens.paddingM),
          AppText.caption(
            state.error!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildGenderInput(EditProfileState state, AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GenderOption(
          label: getString(appStr.descriptionMale, 'description_male'),
          isSelected: state.selectedGender == Gender.male,
          onTap: () => _onGenderSelected(Gender.male),
          colors: colors,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _GenderOption(
          label: getString(appStr.descriptionFemale, 'description_female'),
          isSelected: state.selectedGender == Gender.female,
          onTap: () => _onGenderSelected(Gender.female),
          colors: colors,
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppDimens.paddingM),
          AppText.caption(
            state.error!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneInput(EditProfileState state, AppColorPalette colors) {
    final phoneLabel = getString(appStr.hintPhoneNumber, 'hint_phone_number');
    final notifier = ref.read(editProfileViewModelProvider.notifier);
    final phoneCode = state.selectedCountry?.displayPhoneCode ?? state.countryPhoneCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(phoneLabel, fontWeight: FontWeight.w500),
        const SizedBox(height: AppDimens.paddingS),
        AppPhoneTextField(
          controller: _phoneController,
          hintText: phoneLabel,
          countryCodeWidget: _buildCountryCodeSelector(colors, state, notifier),
          onChanged: _onPhoneChanged,
          showPrefixInTextField: true,
          selectedCountryPhoneCode: phoneCode,
        ),
        if (state.isPhoneVerificationEnabled) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            getString(appStr.descriptionVerificationCodeSendToNumber,
                'description_verification_code_send_to_number'),
            color: colors.colorText,
          ),
        ],
        if (state.phoneError != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.phoneError!,
            color: colors.colorWarning,
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: AppDimens.paddingM),
          AppText.caption(
            state.error!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildCountryCodeSelector(
    AppColorPalette colors,
    EditProfileState state,
    EditProfileViewModel notifier,
  ) {
    final selectedCountry = state.selectedCountry;
    final countryCode = selectedCountry?.alpha2 ?? '';
    final phoneCode = selectedCountry?.displayPhoneCode ?? state.countryPhoneCode;

    return InkWell(
      key: _countryCodeKey,
      onTap: () {
        if (state.countries.isEmpty) return;
        _showCountryPicker(state.countries, selectedCountry, notifier);
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (countryCode.isNotEmpty) ...[
                AppText.body(
                  countryCode,
                  fontSize: AppTypos.textS,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(width: AppDimens.paddingS),
              ],
              AppText.body(
                phoneCode,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(width: AppDimens.paddingXS),
              Icon(
                Icons.keyboard_arrow_down,
                size: AppDimens.iconSizeSmall,
                color: colors.colorText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput(EditProfileState state, AppColorPalette colors) {
    final emailLabel = getString(appStr.descriptionEmail, 'description_email');
    final emailHint = getString(appStr.hintEmailExample, 'hint_email_example');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(emailLabel, fontWeight: FontWeight.w500),
        const SizedBox(height: AppDimens.paddingS),
        AppTextField(
          controller: _emailController,
          hintText: emailHint,
          keyboardType: TextInputType.emailAddress,
          onChanged: _onEmailChanged,
        ),
        if (state.isEmailVerificationEnabled) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            getString(appStr.descriptionProfileEmail, 'description_profile_email'),
            color: colors.colorText,
          ),
        ],
        if (state.emailError != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.emailError!,
            color: colors.colorWarning,
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: AppDimens.paddingM),
          AppText.caption(
            state.error!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildOtpInput(EditProfileState state, AppColorPalette colors) {
    final resendText = state.field == EditProfileField.phone
        ? getString(appStr.descriptionResendPhoneCode, 'description_resend_phone_code')
        : getString(appStr.descriptionResendEmailCode, 'description_resend_email_code');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OtpInputField(
          length: state.otpLength,
          controller: _otpController,
          onChanged: _onOtpChanged,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextButton(
          text: state.resendSeconds > 0
              ? '$resendText (${_formattedResendTime(state.resendSeconds)})'
              : resendText,
          onTap: state.resendSeconds > 0 ? null : _resendOtp,
          colors: colors,
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppDimens.paddingM),
          AppText.caption(
            state.error!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(EditProfileState state, AppColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.padding),
      child: AppFilledButton(
        text: getString(appStr.buttonUpdate, 'button_update'),
        onPressed: state.canProceed ? _onUpdatePressed : null,
        isLoading: state.isLoading,
        enabled: state.canProceed,
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required VoidCallback? onTap,
    required AppColorPalette colors,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled
                ? colors.colorText
                : colors.colorText.withValues(alpha: 0.3),
            width: AppDimens.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        ),
        child: AppText.body(
          text,
          color: isEnabled
              ? colors.colorText
              : colors.colorText.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Gender selection option widget
class _GenderOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorPalette colors;

  const _GenderOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          color: isSelected ? colors.colorPrimary.withValues(alpha: 0.1) : colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          border: Border.all(
            color: isSelected ? colors.colorPrimary : colors.colorText,
            width: isSelected ? AppDimens.borderWidthThick : AppDimens.borderWidth,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText.body(
                label,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.colorPrimary : colors.colorText,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.colorPrimary,
                size: AppDimens.iconSize,
              ),
          ],
        ),
      ),
    );
  }
}
