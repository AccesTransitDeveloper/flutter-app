import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../models/webview_data_model.dart';
import '../../../core/localization/string_constants.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/validator/validator.dart';
import '../../../core/utils/resend_timer_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_text_field.dart';
import '../../../views/widgets/otp_input_field.dart';
import '../../../views/widgets/country_picker_dropdown.dart';
import '../../../models/responses/auth/country_response.dart';
import '../../../viewmodels/register_viewmodel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final RegisterOrigin origin;

  // Phone registration params
  final String? phoneNumber;
  final String? countryPhoneCode;

  // Email registration params
  final String? email;

  // Social registration params
  final String? socialId;
  final int? authMethod;
  final String? firstName;
  final String? lastName;

  // Common params
  final List<Country> countries;
  final Country? selectedCountry;

  const RegisterScreen.phone({
    super.key,
    required String phoneNumber,
    required String countryPhoneCode,
    required this.countries,
    this.selectedCountry,
  })  : origin = RegisterOrigin.phone,
        phoneNumber = phoneNumber,
        countryPhoneCode = countryPhoneCode,
        email = null,
        socialId = null,
        authMethod = null,
        firstName = null,
        lastName = null;

  const RegisterScreen.email({
    super.key,
    required String email,
    required this.countries,
    this.selectedCountry,
  })  : origin = RegisterOrigin.email,
        email = email,
        phoneNumber = null,
        countryPhoneCode = null,
        socialId = null,
        authMethod = null,
        firstName = null,
        lastName = null;

  const RegisterScreen.social({
    super.key,
    required String socialId,
    required int authMethod,
    this.firstName,
    this.lastName,
    this.email,
    required this.countries,
    this.selectedCountry,
  })  : origin = RegisterOrigin.social,
        socialId = socialId,
        authMethod = authMethod,
        phoneNumber = null,
        countryPhoneCode = null;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneOtpController = TextEditingController();
  final _emailOtpController = TextEditingController();
  final _referralController = TextEditingController();

  // Country picker
  final _countryCodeKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  // Timer for resend
  Timer? _resendTimer;
  Timer? _resendEmailTimer;
  bool _obscurePassword = true;

  // Gesture recognizers for terms links
  TapGestureRecognizer? _termsRecognizer;
  TapGestureRecognizer? _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFlow();
    });
  }

  void _initializeFlow() {
    final notifier = ref.read(registerViewModelProvider.notifier);

    if (widget.origin == RegisterOrigin.phone) {
      notifier.initPhoneRegistration(
        phoneNumber: widget.phoneNumber!,
        countryPhoneCode: widget.countryPhoneCode!,
        countries: widget.countries,
        selectedCountry: widget.selectedCountry,
      );
    } else if (widget.origin == RegisterOrigin.social) {
      notifier.initSocialRegistration(
        socialId: widget.socialId!,
        authMethod: widget.authMethod!,
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        countries: widget.countries,
        selectedCountry: widget.selectedCountry,
      );
      // Pre-fill name controllers from social profile
      if (widget.firstName != null) {
        _firstNameController.text = widget.firstName!;
      }
      if (widget.lastName != null) {
        _lastNameController.text = widget.lastName!;
      }
    } else {
      notifier.initEmailRegistration(
        email: widget.email!,
        countries: widget.countries,
        selectedCountry: widget.selectedCountry,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneOtpController.dispose();
    _emailOtpController.dispose();
    _referralController.dispose();
    _resendTimer?.cancel();
    _resendEmailTimer?.cancel();
    _removeOverlay();
    _termsRecognizer?.dispose();
    _privacyRecognizer?.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Phone and email each get their own countdown — one shared timer meant
  /// resending either code restarted the other's cooldown.
  void _startResendEmailTimer() {
    final notifier = ref.read(registerViewModelProvider.notifier);
    notifier.updateResendEmailSeconds(ValidatorConfig.resendOtpTime);

    _resendEmailTimer?.cancel();
    _resendEmailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSeconds =
          ref.read(registerViewModelProvider).resendEmailSeconds;
      if (currentSeconds > 0) {
        notifier.updateResendEmailSeconds(currentSeconds - 1);
      } else {
        timer.cancel();
      }
    });
  }

  void _startResendTimer() {
    final notifier = ref.read(registerViewModelProvider.notifier);
    notifier.updateResendSeconds(ValidatorConfig.resendOtpTime);

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSeconds = ref.read(registerViewModelProvider).resendSeconds;
      if (currentSeconds > 0) {
        notifier.updateResendSeconds(currentSeconds - 1);
      } else {
        timer.cancel();
      }
    });
  }

  String _formattedResendTime(int seconds) {
    return ResendTimerHelper.formatTime(seconds);
  }

  void _showCountryPicker(
    List<Country> countries,
    Country? selectedCountry,
    RegisterViewModel notifier,
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

  // Event handlers
  void _onFirstNameChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setFirstName(value);
  }

  void _onLastNameChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setLastName(value);
  }

  void _onTermsChanged(bool? value) {
    ref.read(registerViewModelProvider.notifier).setTermsAccepted(value ?? false);
  }

  void _onEmailChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setEmail(value);
  }

  void _onPhoneChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setPhoneNumber(value);
  }

  void _onPasswordChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setPassword(value);
  }

  void _onPhoneOtpChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setPhoneOtp(value);
  }

  void _onEmailOtpChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setEmailOtp(value);
  }

  void _onReferralCodeChanged(String value) {
    ref.read(registerViewModelProvider.notifier).setReferralCode(value);
  }

  Future<void> _onNextPressed() async {
    final state = ref.read(registerViewModelProvider);
    final notifier = ref.read(registerViewModelProvider.notifier);

    if (!state.canProceed) return;

    FocusScope.of(context).unfocus();

    final success = await notifier.validateAndProceed();

    if (success) {
      final currentState = ref.read(registerViewModelProvider);
      if (currentState.currentStep == RegisterStep.otp) {
        _startResendTimer();
      }
    }

    if (state.isSignUpSuccess && mounted) {
      _navigateToHome();
    }
  }

  Future<void> _resendPhoneOtp() async {
    final state = ref.read(registerViewModelProvider);
    if (state.resendSeconds > 0) return;

    final notifier = ref.read(registerViewModelProvider.notifier);
    final success = await notifier.resendPhoneOtp();
    if (success) {
      _phoneOtpController.clear();
      _startResendTimer();
    }
  }

  Future<void> _resendEmailOtp() async {
    final state = ref.read(registerViewModelProvider);
    if (state.resendEmailSeconds > 0) return;

    final notifier = ref.read(registerViewModelProvider.notifier);
    final success = await notifier.resendEmailOtp();
    if (success) {
      _emailOtpController.clear();
      _startResendEmailTimer();
    }
  }

  void _navigateToHome() {
    context.navigateToHome();
  }

  void _onBackPressed() {
    final state = ref.read(registerViewModelProvider);
    final notifier = ref.read(registerViewModelProvider.notifier);

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).unfocus();
      if (state.currentStep == RegisterStep.name) {
        context.goBack();
      } else {
        _resendTimer?.cancel();
        notifier.goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final colors = context.colors;

    // Listen for sign up success
    ref.listen<RegisterState>(registerViewModelProvider, (previous, next) {
      if (next.isSignUpSuccess && mounted) {
        _navigateToHome();
      }
    });

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
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

  bool _hasSubtitle(RegisterState state) {
    return state.currentStep == RegisterStep.name ||
        state.currentStep == RegisterStep.contact ||
        state.currentStep == RegisterStep.terms;
  }

  Widget _buildHeader(RegisterState state, AppColorPalette colors) {
    String title;
    switch (state.currentStep) {
      case RegisterStep.name:
        title = getString(appStr.headingWhatIsYourName, 'heading_what_is_your_name');
        break;
      case RegisterStep.terms:
        final appName = getString(appStr.appName, 'app_name');
        title = getString(appStr.headingAcceptTermsAndReviewPrivacyNotice, 'heading_accept_terms_and_review_privacy_notice')
            .replacePlaceholders({StringConstant.appName: appName});
        break;
      case RegisterStep.contact:
        title = state.origin == RegisterOrigin.phone
            ? getString(appStr.headingWhatIsYourEmailAddress, 'heading_what_is_your_email_address')
            : getString(appStr.hintPhoneNumber, 'hint_phone_number');
        break;
      case RegisterStep.password:
        title = getString(appStr.headingCreatePassword, 'heading_create_password');
        break;
      case RegisterStep.otp:
        title = getString(appStr.headingVerifyAccount, 'heading_verify_account');
        break;
      case RegisterStep.referral:
        title = getString(appStr.headingHaveReferralCode, 'heading_have_referral_code');
        break;
    }

    return AppText.heading(title);
  }

  Widget _buildSubtitle(RegisterState state, AppColorPalette colors) {
    String subtitle;
    switch (state.currentStep) {
      case RegisterStep.name:
        subtitle = getString(appStr.descriptionLetUsKnowHowToProperlyAddressYou, 'description_let_us_know_how_to_properly_address_you');
        break;
      case RegisterStep.terms:
        subtitle = '';
        break;
      case RegisterStep.contact:
        subtitle = state.origin == RegisterOrigin.phone
            ? ''
            : getString(appStr.descriptionYouWillUseThisNumber, 'description_you_will_use_this_number');
        break;
      default:
        return const SizedBox.shrink();
    }

    if (subtitle.isEmpty) return const SizedBox.shrink();

    return AppText.body(
      subtitle,
      color: colors.colorText,
    );
  }

  Widget _buildInputField(RegisterState state, AppColorPalette colors) {
    switch (state.currentStep) {
      case RegisterStep.name:
        return _buildNameInput(state, colors);
      case RegisterStep.terms:
        return _buildTermsInput(state, colors);
      case RegisterStep.contact:
        // Phone origin needs email; email/social origin needs phone
        return state.origin == RegisterOrigin.phone
            ? _buildEmailInput(state, colors)
            : _buildPhoneInput(state, colors);
      case RegisterStep.password:
        return _buildPasswordInput(state, colors);
      case RegisterStep.otp:
        return _buildOtpInput(state, colors);
      case RegisterStep.referral:
        return _buildReferralInput(state, colors);
    }
  }

  Widget _buildNameInput(RegisterState state, AppColorPalette colors) {
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
      ],
    );
  }

  Widget _buildTermsInput(RegisterState state, AppColorPalette colors) {
    final termsText = getString(appStr.descriptionTermsOfUse, 'description_terms_of_use');
    final privacyText = getString(appStr.descriptionPrivacyNotice, 'description_privacy_notice');

    // Build the terms description with clickable links
    final fullTermsText = getString(appStr.descriptionAgreeTerms, 'description_agree_terms');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTermsRichText(
          fullText: fullTermsText,
          termsText: termsText,
          privacyText: privacyText,
          termsUrl: state.termsAndConditionsUrl,
          privacyUrl: state.privacyPolicyUrl,
          colors: colors,
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.error!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildTermsRichText({
    required String fullText,
    required String termsText,
    required String privacyText,
    required String? termsUrl,
    required String? privacyUrl,
    required AppColorPalette colors,
  }) {
    // Replace placeholders with actual text for display
    final displayText = fullText
        .replacePlaceholders({StringConstant.terms: termsText, StringConstant.privacy: privacyText});

    // Find positions of terms and privacy in the display text
    final termsStart = displayText.indexOf(termsText);
    final termsEnd = termsStart + termsText.length;
    final privacyStart = displayText.indexOf(privacyText);
    final privacyEnd = privacyStart + privacyText.length;

    // Initialize recognizers only once
    _termsRecognizer ??= TapGestureRecognizer();
    _privacyRecognizer ??= TapGestureRecognizer();
    _termsRecognizer!.onTap = () => _openUrl(termsUrl);
    _privacyRecognizer!.onTap = () => _openUrl(privacyUrl);

    final spans = <TextSpan>[];

    if (termsStart >= 0 && privacyStart >= 0) {
      // Add text before terms
      if (termsStart > 0) {
        spans.add(TextSpan(text: displayText.substring(0, termsStart)));
      }

      // Add terms link
      spans.add(TextSpan(
        text: termsText,
        style: TextStyle(
          color: colors.colorPrimary,
          decoration: TextDecoration.underline,
        ),
        recognizer: _termsRecognizer,
      ));

      // Add text between terms and privacy
      if (privacyStart > termsEnd) {
        spans.add(TextSpan(text: displayText.substring(termsEnd, privacyStart)));
      }

      // Add privacy link
      spans.add(TextSpan(
        text: privacyText,
        style: TextStyle(
          color: colors.colorPrimary,
          decoration: TextDecoration.underline,
        ),
        recognizer: _privacyRecognizer,
      ));

      // Add text after privacy
      if (privacyEnd < displayText.length) {
        spans.add(TextSpan(text: displayText.substring(privacyEnd)));
      }
    } else {
      spans.add(TextSpan(text: displayText));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: AppTypos.textM,
          color: colors.colorText,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }

  void _openUrl(String? url) {
    if (url == null || url.isEmpty) return;
    context.navigateToWebView(
      webViewData: WebViewDataModel(webURL: url),
    );
  }

  Widget _buildEmailInput(RegisterState state, AppColorPalette colors) {
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
        if (state.emailError != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.emailError!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneInput(RegisterState state, AppColorPalette colors) {
    final notifier = ref.read(registerViewModelProvider.notifier);
    final phoneLabel = getString(appStr.hintPhoneNumber, 'hint_phone_number');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(phoneLabel, fontWeight: FontWeight.w500),
        const SizedBox(height: AppDimens.paddingS),
        AppPhoneTextField(
          controller: _phoneController,
          hintText: getString(appStr.hintNumberExample, 'hint_number_example'),
          countryCodeWidget: _buildCountryCodeSelector(colors, state, notifier),
          onChanged: _onPhoneChanged,
          showPrefixInTextField: true,
          selectedCountryPhoneCode: state.selectedCountry?.displayPhoneCode ?? '',
        ),
        if (state.isPhoneVerificationEnabled) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            getString(appStr.descriptionVerificationCodeSendToNumber, 'description_verification_code_send_to_number'),
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
      ],
    );
  }

  Widget _buildCountryCodeSelector(
    AppColorPalette colors,
    RegisterState state,
    RegisterViewModel notifier,
  ) {
    final selectedCountry = state.selectedCountry;
    final phoneCode = selectedCountry?.displayPhoneCode ?? '';

    final countryCode = selectedCountry?.alpha2 ?? '';

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
              AppText.body(
                countryCode,
                fontSize: AppTypos.textS,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(width: AppDimens.paddingS),
              AppText.body(phoneCode, fontWeight: FontWeight.w500),
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

  Widget _buildPasswordInput(RegisterState state, AppColorPalette colors) {
    final passwordLabel = getString(appStr.descriptionPassword, 'description_password');
    final passwordHint = getString(appStr.hintPassword, 'hint_password');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(passwordLabel, fontWeight: FontWeight.w500),
        const SizedBox(height: AppDimens.paddingS),
        AppTextField(
          controller: _passwordController,
          hintText: passwordHint,
          obscureText: _obscurePassword,
          onChanged: _onPasswordChanged,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: colors.colorText,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        if (state.passwordError != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.passwordError!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildOtpInput(RegisterState state, AppColorPalette colors) {
    final phoneOtpText = getString(appStr.descriptionEnterOtpSentTo, 'description_enter_otp_sent_to')
        .replacePlaceholders({
          StringConstant.leftParam: state.otpLength.toString(),
          StringConstant.rightParam: state.phoneNumber,
        });
    final emailOtpText = getString(appStr.descriptionEnterOtpSentTo, 'description_enter_otp_sent_to')
        .replacePlaceholders({
          StringConstant.leftParam: state.otpLength.toString(),
          StringConstant.rightParam: state.email,
        });
    final resendPhoneText = getString(appStr.descriptionResendPhoneCode, 'description_resend_phone_code');
    final resendEmailText = getString(appStr.descriptionResendEmailCode, 'description_resend_email_code');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone OTP - only show if phone verification is enabled
        if (state.isPhoneVerificationEnabled) ...[
          AppText.body(
            phoneOtpText,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: AppDimens.paddingM),
          OtpInputField(
            length: state.otpLength,
            controller: _phoneOtpController,
            onChanged: _onPhoneOtpChanged,
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildTextButton(
            text: state.resendSeconds > 0
                ? '$resendPhoneText (${_formattedResendTime(state.resendSeconds)})'
                : resendPhoneText,
            onTap: state.resendSeconds > 0 ? null : _resendPhoneOtp,
            colors: colors,
          ),
        ],

        // Spacing between phone and email OTP if both are shown
        if (state.isPhoneVerificationEnabled && state.isEmailVerificationEnabled)
          const SizedBox(height: AppDimens.paddingXXL),

        // Email OTP - only show if email verification is enabled
        if (state.isEmailVerificationEnabled) ...[
          AppText.body(
            emailOtpText,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: AppDimens.paddingM),
          OtpInputField(
            length: state.otpLength,
            controller: _emailOtpController,
            onChanged: _onEmailOtpChanged,
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildTextButton(
            text: state.resendEmailSeconds > 0
                ? '$resendEmailText (${_formattedResendTime(state.resendEmailSeconds)})'
                : resendEmailText,
            onTap: state.resendEmailSeconds > 0 ? null : _resendEmailOtp,
            colors: colors,
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

  Widget _buildReferralInput(RegisterState state, AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _referralController,
          hintText: getString(appStr.hintReferralCode, 'hint_referral_code'),
          onChanged: _onReferralCodeChanged,
        ),
        if (state.referralError != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          AppText.caption(
            state.referralError!,
            color: colors.colorWarning,
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(RegisterState state, AppColorPalette colors) {
    final isTermsStep = state.currentStep == RegisterStep.terms;
    final agreeText = getString(appStr.descriptionIAgree, 'description_i_agree');

    return Padding(
      padding: const EdgeInsets.all(AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show "I Agree" checkbox only on terms step
          if (isTermsStep) ...[
            const Divider(),
            InkWell(
              onTap: () => _onTermsChanged(!state.termsAccepted),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.body(agreeText, fontWeight: FontWeight.w500),
                    Checkbox(
                      value: state.termsAccepted,
                      onChanged: _onTermsChanged,
                      activeColor: colors.colorText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppCircleButton(
                icon: Icons.arrow_back,
                onPressed: _onBackPressed,
              ),
              AppNextButton(
                text: getString(appStr.buttonNext, 'button_next'),
                onPressed: _onNextPressed,
                isLoading: state.isLoading,
                enabled: state.canProceed,
              ),
            ],
          ),
        ],
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
