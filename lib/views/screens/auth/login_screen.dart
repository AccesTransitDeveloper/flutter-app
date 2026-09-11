import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/login_viewmodel.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_text_field.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_divider.dart';
import '../../../views/widgets/country_picker_dropdown.dart';
import '../../../models/responses/auth/country_response.dart';
import '../../widgets/move_server_bottom_sheet.dart';
import '../../widgets/multi_tap_detector.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _countryCodeKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _phoneController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onContinuePressed(
    LoginState loginState,
    LoginViewModel loginNotifier,
  ) async {
    // Close keyboard before API call
    FocusScope.of(context).unfocus();

    final result = await loginNotifier.checkPhoneRegistered();
    if (!mounted) return;

    switch (result) {
      case CheckRegisteredResult.registered:
        context.navigateToVerificationPhone(
          phoneNumber: loginState.phoneNumber,
          countryPhoneCode: loginState.selectedCountry?.displayPhoneCode ?? '',
          supportsOtp: loginState.phoneSupportsOtp,
          supportsPassword: loginState.phoneSupportsPassword,
        );
      case CheckRegisteredResult.notRegistered:
        context.navigateToRegisterPhone(
          phoneNumber: loginState.phoneNumber,
          countryPhoneCode: loginState.selectedCountry?.displayPhoneCode ?? '',
          countries: loginState.countries,
          selectedCountry: loginState.selectedCountry,
        );
      case CheckRegisteredResult.validationError:
        // Error already shown in state
        break;
    }
  }

  Future<void> _onSocialLoginPressed(String provider) async {
    FocusScope.of(context).unfocus();

    final loginNotifier = ref.read(loginViewModelProvider.notifier);
    await loginNotifier.loginWithSocial(provider);
    if (!mounted) return;

    final loginState = ref.read(loginViewModelProvider);
    if (loginState.isSocialLoginSuccess) {
      context.navigateToHome();
    }
  }

  void _onEmailLoginPressed(LoginState loginState) {
    // Close keyboard before navigation
    FocusScope.of(context).unfocus();

    context.navigateToVerificationEmail(
      supportsOtp: loginState.emailSupportsOtp,
      supportsPassword: loginState.emailSupportsPassword,
    );
  }

  bool _showAppleButton(LoginState loginState) =>
      loginState.showAppleLogin && Platform.isIOS;

  void _showCountryPicker(
    List<Country> countries,
    Country? selectedCountry,
    LoginViewModel loginNotifier,
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
          loginNotifier.setSelectedCountry(country);
          _removeOverlay();
        },
        onDismiss: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final loginNotifier = ref.read(loginViewModelProvider.notifier);
    final colors = context.colors;

    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDimens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimens.paddingXL),

              // Header (5-tap to open server switcher)
              MultiTapDetector(
                onMultiTap: () => showMoveServerBottomSheet(context, ref),
                child: AppText.heading(
                  getString(appStr.headingEnterYourMobileNumber, 'heading_enter_your_mobile_number'),
                ),
              ),

              const SizedBox(height: AppDimens.paddingXXL),

              // Phone number input
              AppPhoneTextField(
                controller: _phoneController,
                hintText: getString(appStr.hintNumberExample, 'hint_number_example'),
                countryCodeWidget: _buildCountryCodeSelector(
                  colors,
                  loginState,
                  loginNotifier,
                ),
                onChanged: loginNotifier.setPhoneNumber,
                selectedCountryPhoneCode: loginState.selectedCountry?.displayPhoneCode,
              ),

              // Phone error message
              if (loginState.phoneError != null) ...[
                const SizedBox(height: AppDimens.paddingS),
                AppText.caption(
                  loginState.phoneError!,
                  color: colors.colorWarning,
                ),
              ],

              const SizedBox(height: AppDimens.paddingXL),

              // Continue button
              AppFilledButton(
                text: getString(appStr.buttonContinue, 'button_continue'),
                isLoading: loginState.loadingAction == 'phone',
                onPressed: () => _onContinuePressed(loginState, loginNotifier),
              ),

              // Show divider only if there are social/email login options
              if (loginState.showGoogleLogin ||
                  _showAppleButton(loginState) ||
                  loginState.showEmailLogin) ...[
                const SizedBox(height: AppDimens.paddingXL),
                const AppDivider.or(),
                const SizedBox(height: AppDimens.paddingXL),
              ],

              // Social login buttons
              if (loginState.showGoogleLogin)
                AppFilledIconButton(
                  text: getString(appStr.buttonContinueWithGoogle, 'button_continue_with_google'),
                  icon: Icon(
                    Icons.g_mobiledata,
                    size: AppDimens.iconSizeLarge,
                    color: colors.colorText,
                  ),
                  backgroundColor: colors.colorBackgroundGray,
                  borderColor: Colors.transparent,
                  isLoading: loginState.loadingAction == 'google',
                  onPressed: () => _onSocialLoginPressed('google'),
                ),

              if (loginState.showGoogleLogin && _showAppleButton(loginState))
                const SizedBox(height: AppDimens.paddingM),

              if (_showAppleButton(loginState))
                AppFilledIconButton(
                  text: getString(appStr.buttonContinueWithApple, 'button_continue_with_apple'),
                  icon: Icon(
                    Icons.apple,
                    size: AppDimens.iconSize,
                    color: colors.colorText,
                  ),
                  backgroundColor: colors.colorBackgroundGray,
                  borderColor: Colors.transparent,
                  isLoading: loginState.loadingAction == 'apple',
                  onPressed: () => _onSocialLoginPressed('apple'),
                ),

              if ((loginState.showGoogleLogin || _showAppleButton(loginState)) &&
                  loginState.showEmailLogin)
                const SizedBox(height: AppDimens.paddingM),

              if (loginState.showEmailLogin)
                AppFilledIconButton(
                  text: getString(appStr.buttonContinueWithEmail, 'button_continue_with_email'),
                  icon: Icon(
                    Icons.mail_outline,
                    size: AppDimens.iconSize,
                    color: colors.colorText,
                  ),
                  backgroundColor: colors.colorBackgroundGray,
                  borderColor: Colors.transparent,
                  isLoading: loginState.loadingAction == 'email',
                  onPressed: () => _onEmailLoginPressed(loginState),
                ),

              // Error message
              if (loginState.error != null) ...[
                const SizedBox(height: AppDimens.padding),
                AppText.caption(
                  loginState.error!,
                  color: colors.colorWarning,
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppDimens.paddingXXL),

              // Terms and privacy
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.paddingL),
                  child: AppText.caption(
                    getString(appStr.descriptionByContinuingYouAgree, 'description_by_continuing_you_agree'),
                    color: colors.colorText,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryCodeSelector(
    AppColorPalette colors,
    LoginState loginState,
    LoginViewModel loginNotifier,
  ) {
    final selectedCountry = loginState.selectedCountry;
    // Placeholder until the country list loads and the default is selected.
    final countryCode = selectedCountry?.alpha2 ?? 'US';
    final phoneCode = selectedCountry?.displayPhoneCode ?? '+1';

    return InkWell(
      key: _countryCodeKey,
      onTap: () {
        if (loginState.countries.isEmpty) return;
        _showCountryPicker(
          loginState.countries,
          selectedCountry,
          loginNotifier,
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Country code text
              AppText.body(
                countryCode,
                fontSize: AppTypos.textS,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(width: AppDimens.paddingS),
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
}
