import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
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
import '../../../viewmodels/verification_viewmodel.dart';
import '../../../viewmodels/login_viewmodel.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final LoginType loginType;

  // Phone login params
  final String? phoneNumber;
  final String? countryPhoneCode;

  // Common params
  final int otpLength;
  final bool supportsOtp;
  final bool supportsPassword;

  const VerificationScreen.phone({
    super.key,
    required String phoneNumber,
    required String countryPhoneCode,
    this.otpLength = 6,
    this.supportsOtp = true,
    this.supportsPassword = false,
  })  : loginType = LoginType.phone,
        phoneNumber = phoneNumber,
        countryPhoneCode = countryPhoneCode;

  const VerificationScreen.email({
    super.key,
    this.otpLength = 6,
    this.supportsOtp = true,
    this.supportsPassword = false,
  })  : loginType = LoginType.email,
        phoneNumber = null,
        countryPhoneCode = null;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  // Timer for resend
  Timer? _resendTimer;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFlow();
    });
  }

  void _initializeFlow() {
    final notifier = ref.read(verificationViewModelProvider.notifier);

    if (widget.loginType == LoginType.phone) {
      notifier.initPhoneVerification(
        phoneNumber: widget.phoneNumber!,
        countryPhoneCode: widget.countryPhoneCode!,
        otpLength: widget.otpLength,
        supportsOtp: widget.supportsOtp,
        supportsPassword: widget.supportsPassword,
      );
      // Start resend timer for phone OTP flow
      if (widget.supportsOtp) {
        _startResendTimer();
      }
    } else {
      notifier.initEmailVerification(
        otpLength: widget.otpLength,
        supportsOtp: widget.supportsOtp,
        supportsPassword: widget.supportsPassword,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    final notifier = ref.read(verificationViewModelProvider.notifier);
    notifier.updateResendSeconds(ValidatorConfig.resendOtpTime);

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSeconds = ref.read(verificationViewModelProvider).resendSeconds;
      if (currentSeconds > 0) {
        notifier.updateResendSeconds(currentSeconds - 1);
      } else {
        timer.cancel();
      }
    });
  }

  // Formatting helpers
  String _formattedPhoneNumber(VerificationState state) {
    final phone = state.phoneNumber;
    if (phone.length >= 10) {
      final areaCode = phone.substring(0, 3);
      final middle = phone.substring(3, 6);
      final last = phone.substring(6);
      return '(${state.countryPhoneCode}) $areaCode-$middle-$last';
    }
    return '(${state.countryPhoneCode}) $phone';
  }

  String _formattedResendTime(int seconds) {
    return ResendTimerHelper.formatTime(seconds);
  }

  // Event handlers
  void _onEmailChanged(String email) {
    ref.read(verificationViewModelProvider.notifier).setEmail(email);
  }

  void _onOtpChanged(String otp) {
    ref.read(verificationViewModelProvider.notifier).setOtp(otp);
  }

  void _onOtpCompleted(String otp) {
    // Auto-verify when OTP is complete (optional)
  }

  void _onPasswordChanged(String password) {
    ref.read(verificationViewModelProvider.notifier).setPassword(password);
  }

  Future<void> _toggleAuthMode() async {
    final notifier = ref.read(verificationViewModelProvider.notifier);
    final currentAuthMode = ref.read(verificationViewModelProvider).authMode;

    debugPrint('_toggleAuthMode called, currentAuthMode: $currentAuthMode');

    if (currentAuthMode == AuthMode.otp) {
      // Switching from OTP to password - just cancel timer, no OTP generation
      debugPrint('Switching to password mode');
      _resendTimer?.cancel();
      notifier.toggleAuthMode();
    } else {
      // Switching from password to OTP - generateOtp is called in ViewModel
      debugPrint('Switching to OTP mode');
      notifier.toggleAuthMode();
      _startResendTimer();
    }
  }

  Future<void> _onNextPressed() async {
    final state = ref.read(verificationViewModelProvider);
    final notifier = ref.read(verificationViewModelProvider.notifier);

    if (!state.canProceed) return;

    switch (state.currentStep) {
      case VerificationStep.input:
        final result = await notifier.checkEmailRegistered();
        if (!mounted) return;

        switch (result) {
          case CheckEmailResult.registered:
            if (state.supportsOtp) {
              _startResendTimer();
            }
          case CheckEmailResult.notRegistered:
            // Navigate to register screen with email
            final loginState = ref.read(loginViewModelProvider);
            context.navigateToRegisterEmail(
              email: state.email,
              countries: loginState.countries,
              selectedCountry: loginState.selectedCountry,
            );
          case CheckEmailResult.validationError:
            // Error already shown in state
            break;
        }
        break;
      case VerificationStep.otp:
      case VerificationStep.password:
        final success = await notifier.signIn();
        if (success && mounted) {
          _navigateToHome();
        }
        break;
    }
  }

  Future<void> _resendOtp() async {
    final state = ref.read(verificationViewModelProvider);
    if (state.resendSeconds > 0) return;

    final notifier = ref.read(verificationViewModelProvider.notifier);
    final success = await notifier.resendOtp();
    if (success) {
      _startResendTimer();
    }
  }

  void _onForgotPasswordPressed() {
    final state = ref.read(verificationViewModelProvider);
    FocusScope.of(context).unfocus();

    if (state.loginType == LoginType.phone) {
      context.navigateToForgotPasswordPhone(
        phoneNumber: state.phoneNumber,
        countryPhoneCode: state.countryPhoneCode,
        otpLength: state.otpLength,
      );
    } else {
      context.navigateToForgotPasswordEmail(
        email: state.email,
        otpLength: state.otpLength,
      );
    }
  }

  void _navigateToHome() {
    context.navigateToHome();
  }

  void _onBackPressed() {
    final state = ref.read(verificationViewModelProvider);
    final notifier = ref.read(verificationViewModelProvider.notifier);

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).unfocus();
      // If in OTP/Password step for email, go back to email input
      if (state.loginType == LoginType.email &&
          state.currentStep != VerificationStep.input) {
        _resendTimer?.cancel();
        _otpController.clear();
        _passwordController.clear();
        notifier.goBackToInput();
      } else {
        context.goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationViewModelProvider);
    final colors = context.colors;

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
                    const SizedBox(height: AppDimens.paddingM),
                    _buildChangeLink(state, colors),
                    const SizedBox(height: AppDimens.paddingXXL),
                    _buildInputField(state, colors),
                    const SizedBox(height: AppDimens.paddingXXL),
                    _buildActionButtons(state, colors),
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

  Widget _buildHeader(VerificationState state, AppColorPalette colors) {
    String title;
    switch (state.currentStep) {
      case VerificationStep.input:
        title = getString(appStr.headingWhatIsYourEmailAddress, 'heading_what_is_your_email_address');
        break;
      case VerificationStep.otp:
        final target = state.loginType == LoginType.phone
            ? _formattedPhoneNumber(state)
            : state.email;
        title = getString(appStr.descriptionEnterOtpSentTo, 'description_enter_otp_sent_to')
            .replacePlaceholders({
              StringConstant.leftParam: state.otpLength.toString(),
              StringConstant.rightParam: target,
            });
        break;
      case VerificationStep.password:
        final target = state.loginType == LoginType.phone
            ? _formattedPhoneNumber(state)
            : state.email;
        title = getString(appStr.descriptionEnterPasswordFor, 'description_enter_password_for')
            .replacePlaceholders({StringConstant.value: target});
        break;
    }

    return AppText.title(title);
  }

  Widget _buildChangeLink(VerificationState state, AppColorPalette colors) {
    if (state.currentStep == VerificationStep.input) {
      return const SizedBox.shrink();
    }

    final linkText = state.loginType == LoginType.phone
        ? getString(appStr.descriptionChangedYourMobileNumber, 'description_changed_your_mobile_number')
        : getString(appStr.descriptionChangedYourEmailAddress, 'description_changed_your_email_address');

    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (state.loginType == LoginType.email) {
          _resendTimer?.cancel();
          ref.read(verificationViewModelProvider.notifier).goBackToInput();
        } else {
          context.goBack();
        }
      },
      child: AppText.body(
        linkText,
        color: colors.colorText,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _buildInputField(VerificationState state, AppColorPalette colors) {
    switch (state.currentStep) {
      case VerificationStep.input:
        return _buildEmailInput(state, colors);
      case VerificationStep.otp:
        return _buildOtpInput(state, colors);
      case VerificationStep.password:
        return _buildPasswordInput(state, colors);
    }
  }

  Widget _buildEmailInput(VerificationState state, AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(
          getString(appStr.descriptionEmail, 'description_email'),
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: AppDimens.paddingS),
        AppTextField(
          controller: _emailController,
          hintText: getString(appStr.hintEmailExample, 'hint_email_example'),
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

  Widget _buildOtpInput(VerificationState state, AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OtpInputField(
          length: state.otpLength,
          controller: _otpController,
          onCompleted: _onOtpCompleted,
          onChanged: _onOtpChanged,
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

  Widget _buildPasswordInput(VerificationState state, AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _passwordController,
          hintText: getString(appStr.hintEnterPassword, 'hint_enter_password'),
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

  Widget _buildActionButtons(VerificationState state, AppColorPalette colors) {
    if (state.currentStep == VerificationStep.input) {
      return const SizedBox.shrink();
    }

    if (state.currentStep == VerificationStep.otp) {
      final resendText = getString(appStr.buttonResendOtp, 'button_resend_otp');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextButton(
            text: state.resendSeconds > 0
                ? '$resendText (${_formattedResendTime(state.resendSeconds)})'
                : resendText,
            onTap: state.resendSeconds > 0 ? null : _resendOtp,
            colors: colors,
          ),
          const SizedBox(height: AppDimens.paddingM),
          if (state.supportsBoth)
            _buildTextButton(
              text: getString(appStr.descriptionLoginWithPasswordInstead, 'description_login_with_password_instead'),
              onTap: _toggleAuthMode,
              colors: colors,
            ),
        ],
      );
    }

    // Password step
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextButton(
          text: getString(appStr.buttonForgotPassword, 'button_forgot_password'),
          onTap: _onForgotPasswordPressed,
          colors: colors,
        ),
        const SizedBox(height: AppDimens.paddingM),
        if (state.supportsBoth)
          _buildTextButton(
            text: getString(appStr.descriptionLoginWithOtpInstead, 'description_login_with_otp_instead'),
            onTap: _toggleAuthMode,
            colors: colors,
          ),
      ],
    );
  }

  Widget _buildBottomBar(VerificationState state, AppColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.padding),
      child: Row(
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
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          color: isEnabled
              ? colors.colorBackgroundGray
              : colors.colorBackgroundGray.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(28),
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
