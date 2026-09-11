import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ride_for_other_result.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toolbar.dart';

/// Full-screen form for adding/editing a rider (name + phone).
/// Can be opened blank (manual entry) or pre-filled (after selecting a contact).
class NewRiderFormScreen extends StatefulWidget {
  final String defaultCountryCode;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialPhone;
  final String? initialCountryCode;

  const NewRiderFormScreen({
    super.key,
    required this.defaultCountryCode,
    this.initialFirstName,
    this.initialLastName,
    this.initialPhone,
    this.initialCountryCode,
  });

  @override
  State<NewRiderFormScreen> createState() => _NewRiderFormScreenState();
}

class _NewRiderFormScreenState extends State<NewRiderFormScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    _phoneController.text = widget.initialPhone ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _firstNameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  String get _effectiveCountryCode =>
      widget.initialCountryCode ?? widget.defaultCountryCode;

  void _onAddRider() {
    if (!_isValid) return;

    final result = RideForOtherResult.forOther(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      countryPhoneCode: _effectiveCountryCode,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingNewRider, 'heading_new_rider'),
              onBack: () => Navigator.pop(context),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.padding),
                      decoration: BoxDecoration(
                        color: colors.colorSecondary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimens.buttonRadiusSmall),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.colorText.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: getString(
                                appStr.descriptionDriversWillSeeName,
                                'description_drivers_will_see_name',
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.colorText,
                              ),
                            ),
                            TextSpan(
                              text: getString(
                                appStr.descriptionNameChangeNote,
                                'description_name_change_note',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingXL),

                    // First Name
                    AppText.body(
                      getString(appStr.hintFirstName, 'hint_first_name'),
                      fontWeight: FontWeight.w500,
                      color: colors.colorText,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    AppTextField(
                      controller: _firstNameController,
                      hintText: getString(
                        appStr.hintEnterFirstName,
                        'hint_enter_first_name',
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: _firstNameController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _firstNameController.clear();
                                setState(() {});
                              },
                              child: Icon(Icons.cancel,
                                  color:
                                      colors.colorText.withValues(alpha: 0.4),
                                  size: 20),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),

                    // Last Name
                    AppText.body(
                      getString(appStr.hintLastName, 'hint_last_name'),
                      fontWeight: FontWeight.w500,
                      color: colors.colorText,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    AppTextField(
                      controller: _lastNameController,
                      hintText: getString(
                        appStr.hintEnterLastName,
                        'hint_enter_last_name',
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: _lastNameController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _lastNameController.clear();
                                setState(() {});
                              },
                              child: Icon(Icons.cancel,
                                  color:
                                      colors.colorText.withValues(alpha: 0.4),
                                  size: 20),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),

                    // Phone Number
                    AppText.body(
                      getString(appStr.hintPhoneNumber, 'hint_phone_number'),
                      fontWeight: FontWeight.w500,
                      color: colors.colorText,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country code chip
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingM,
                          ),
                          decoration: BoxDecoration(
                            color: colors.colorBackgroundGray,
                            borderRadius: BorderRadius.circular(
                                AppDimens.buttonRadiusSmall),
                          ),
                          alignment: Alignment.center,
                          child: AppText.body(
                            _effectiveCountryCode,
                            fontWeight: FontWeight.w500,
                            color: colors.colorText,
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingM),
                        // Phone field
                        Expanded(
                          child: AppTextField(
                            controller: _phoneController,
                            hintText: getString(
                              appStr.hintEnterPhoneNumber,
                              'hint_enter_phone_number',
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    AppText.caption(
                      getString(
                        appStr.descriptionPhoneNotShared,
                        'description_phone_not_shared',
                      ),
                      color: colors.colorText.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section - consent text + button
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Consent text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.colorText.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: getString(
                            appStr.descriptionAddRiderConsentPrefix,
                            'description_add_rider_consent_prefix',
                          ),
                        ),
                        TextSpan(
                          text: getString(
                            appStr.buttonAddRider,
                            'button_add_rider',
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.colorText.withValues(alpha: 0.7),
                          ),
                        ),
                        TextSpan(
                          text: getString(
                            appStr.descriptionAddRiderConsentSuffix,
                            'description_add_rider_consent_suffix',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.padding),

                  // Add rider button
                  AppFilledButton(
                    text: getString(appStr.buttonAddRider, 'button_add_rider'),
                    onPressed: _isValid ? _onAddRider : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
