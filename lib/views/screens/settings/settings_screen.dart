import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/managers/permission_manager.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/api/server_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../viewmodels/saved_places_viewmodel.dart';
import '../../../viewmodels/settings_viewmodel.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_text_field.dart';
import '../../../views/widgets/app_toolbar.dart';
import '../../bottomsheets/country_phone_code_bottom_sheet.dart';
import '../../bottomsheets/logout_bottom_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(settingsViewModelProvider);
    final viewModel = ref.read(settingsViewModelProvider.notifier);
    final savedPlacesState = ref.watch(savedPlacesViewModelProvider);
    final entity = state.entity;

    final imageUrl = entity?.imageUrl != null && entity!.imageUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(entity.imageUrl)
        : null;

    final fullName =
        '${entity?.firstName ?? ''} ${entity?.lastName ?? ''}'.trim();
    final phone = entity?.countryPhoneCode != null && entity?.phone != null
        ? '${entity!.countryPhoneCode} ${entity.phone}'
        : '';
    final email = entity?.email ?? '';

    // Listen for navigation and sheet triggers
    ref.listen<SettingsState>(settingsViewModelProvider, (previous, next) {
      if (next.navigateToLogin) {
        viewModel.clearNavigationFlag();
        context.navigateToLogin();
      }

      if (next.snackBarMessage != null && next.snackBarMessage!.isNotEmpty) {
        context.showSnackBar(next.snackBarMessage!);
        viewModel.clearSnackBar();
      }

      if (next.showAuthOptionsBottomSheet && previous?.showAuthOptionsBottomSheet != true) {
        _showAuthOptionsBottomSheet(context, viewModel);
      }

      if (next.showVerifyPasswordBottomSheet && previous?.showVerifyPasswordBottomSheet != true) {
        _showVerifyPasswordBottomSheet(context, viewModel);
      }

      if (next.showDeleteOtpBottomSheet && previous?.showDeleteOtpBottomSheet != true) {
        _showDeleteOtpBottomSheet(context, viewModel);
      }

    });

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingSetting, 'heading_setting'),
            ),
            Expanded(
              child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _ProfileSection(
              imageUrl: imageUrl,
              fullName: fullName.isNotEmpty ? fullName : 'User',
              phone: phone,
              email: email,
              onTap: () async {
                await context.navigateToProfile();
                viewModel.refreshUserData();
              },
            ),

            const _Divider(),

            // Add Home
            _SettingsMenuItem(
              icon: Icons.home_outlined,
              title: getString(appStr.descriptionAddHome, 'description_add_home'),
              subtitle: savedPlacesState.homeAddress?.address,
              onTap: () {
                final home = savedPlacesState.homeAddress;
                if (home != null) {
                  context.navigateToAddSavedPlace(address: home);
                } else {
                  context.navigateToAddSavedPlace(addressType: AddressType.home);
                }
              },
            ),

            // Add Work
            _SettingsMenuItem(
              icon: Icons.work_outline,
              title: getString(appStr.descriptionAddWork, 'description_add_work'),
              subtitle: savedPlacesState.workAddress?.address,
              onTap: () {
                final work = savedPlacesState.workAddress;
                if (work != null) {
                  context.navigateToAddSavedPlace(address: work);
                } else {
                  context.navigateToAddSavedPlace(addressType: AddressType.work);
                }
              },
            ),

            // Shortcuts (Saved Places)
            _SettingsMenuItem(
              icon: Icons.star_outline,
              title: getString(appStr.descriptionShortcuts, 'description_shortcuts'),
              onTap: () => context.navigateToSavedPlaces(),
            ),

            const _Divider(),

            // Appearance
            _SettingsMenuItem(
              icon: Icons.dark_mode_outlined,
              title: getString(appStr.headingAppearance, 'heading_appearance'),
              subtitle: state.themeDisplayName,
              onTap: () => _showThemeBottomSheet(context, state, viewModel),
            ),

            const _Divider(),

            // Language
            _SettingsMenuItem(
              icon: Icons.language_outlined,
              title: getString(appStr.descriptionLanguage, 'description_language'),
              subtitle: state.selectedLanguage.isNotEmpty
                  ? state.selectedLanguage
                  : 'English',
              onTap: () => _showLanguageBottomSheet(context, state, viewModel),
            ),

            const _Divider(),

            // Emergency Contacts
            _SettingsMenuItem(
              icon: Icons.contact_phone_outlined,
              title: getString(appStr.subHeadingEmergencyContacts, 'sub_heading_emergency_contacts'),
              subtitle: state.emergencyContacts.isNotEmpty
                  ? '${state.emergencyContacts.length} contact${state.emergencyContacts.length > 1 ? 's' : ''}'
                  : null,
              onTap: () => _showEmergencyContactsBottomSheet(context, state, viewModel),
            ),

            const _Divider(),

            // Delete Account
            _SettingsMenuItem(
              icon: Icons.delete_outline,
              title: getString(appStr.headingDeleteAccount, 'heading_delete_account'),
              onTap: () =>
                  _showDeleteAccountBottomSheet(context, state, viewModel),
            ),

            // Logout
            _SettingsMenuItem(
              icon: Icons.exit_to_app,
              title: getString(appStr.headingLogout, 'heading_logout'),
              onTap: () => _showLogoutBottomSheet(context, state, viewModel),
            ),

            const SizedBox(height: AppDimens.paddingXL),

            // App Version
            if (state.appVersion.isNotEmpty)
              Center(
                child: AppText.caption(
                  '${getString(appStr.descriptionAppVersion, 'description_app_version')} ${state.appVersion}',
                  color: colors.colorText,
                ),
              ),

            const SizedBox(height: AppDimens.paddingXL),
          ],
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeBottomSheet(
    BuildContext context,
    SettingsState state,
    SettingsViewModel viewModel,
  ) {
    final colors = context.colors;
    final themeNotifier = ref.read(themeProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.title(getString(appStr.descriptionSelectTheme, 'description_select_theme')),
              const SizedBox(height: AppDimens.padding),
              _SelectionOption(
                title: getString(appStr.descriptionLightMode, 'description_light_mode'),
                isSelected: state.selectedTheme == AppThemeMode.light,
                onTap: () {
                  viewModel.setTheme(AppThemeMode.light);
                  themeNotifier.setThemeMode(AppThemeMode.light);
                  context.goBack();
                },
              ),
              _SelectionOption(
                title: getString(appStr.descriptionDarkMode, 'description_dark_mode'),
                isSelected: state.selectedTheme == AppThemeMode.dark,
                onTap: () {
                  viewModel.setTheme(AppThemeMode.dark);
                  themeNotifier.setThemeMode(AppThemeMode.dark);
                  context.goBack();
                },
              ),
              _SelectionOption(
                title: getString(appStr.descriptionSystemDefault, 'description_system_default'),
                isSelected: state.selectedTheme == AppThemeMode.system,
                onTap: () {
                  viewModel.setTheme(AppThemeMode.system);
                  themeNotifier.setThemeMode(AppThemeMode.system);
                  context.goBack();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(
    BuildContext context,
    SettingsState state,
    SettingsViewModel viewModel,
  ) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final currentState = ref.watch(settingsViewModelProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.title(getString(appStr.headingSelectLanguage, 'heading_select_language')),
                  const SizedBox(height: AppDimens.padding),
                  ...currentState.languageList.asMap().entries.map((entry) {
                    final lang = entry.value;
                    return _SelectionOption(
                      title: lang.name,
                      isSelected: lang.isSelected,
                      onTap: () {
                        viewModel.selectLanguage(entry.key);
                        viewModel.applyLanguage();
                        context.goBack();
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteAccountBottomSheet(
    BuildContext context,
    SettingsState state,
    SettingsViewModel viewModel,
  ) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.title(getString(appStr.headingDeleteAccount, 'heading_delete_account')),
              const SizedBox(height: AppDimens.paddingS),
              AppText.body(
                getString(appStr.descriptionDeleteAccount, 'description_delete_account'),
                color: colors.colorText,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      text: getString(appStr.buttonCancel, 'button_cancel'),
                      onPressed: () => context.goBack(),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: AppFilledButton(
                      text: getString(appStr.descriptionDelete, 'description_delete'),
                      onPressed: state.isDeleteLoading
                          ? null
                          : () {
                              context.goBack();
                              viewModel.onYesDeleteAccountClick();
                            },
                      isLoading: state.isDeleteLoading,
                      backgroundColor: colors.colorWarning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Auth Options Sheet ───────────────────────────────────────────────────

  void _showAuthOptionsBottomSheet(BuildContext context, SettingsViewModel viewModel) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.padding),
            child: Consumer(builder: (context, ref, _) {
              final state = ref.watch(settingsViewModelProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.title(
                    getString(null, 'heading_verify_your_identity'),
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  RadioGroup<int>(
                    groupValue: state.authOptions.indexWhere((o) => o.isSelected),
                    onChanged: (v) => viewModel.selectAuthOption(v ?? 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: state.authOptions.asMap().entries.map((e) => InkWell(
                        onTap: () => viewModel.selectAuthOption(e.key),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: e.key,
                                activeColor: colors.colorPrimary,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: AppDimens.paddingS),
                              AppText.body(e.value.label),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingXL),
                  Row(
                    children: [
                      Expanded(
                        child: AppOutlinedButton(
                          text: getString(appStr.buttonCancel, 'button_cancel'),
                          onPressed: () {
                            sheetContext.goBack();
                            viewModel.dismissAuthOptions();
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: AppFilledButton(
                          text: getString(appStr.buttonContinue, 'button_continue'),
                          onPressed: () {
                            sheetContext.goBack();
                            viewModel.confirmAuthOption();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // ─── Verify Password Sheet ────────────────────────────────────────────────

  void _showVerifyPasswordBottomSheet(BuildContext context, SettingsViewModel viewModel) {
    final colors = context.colors;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppDimens.padding, AppDimens.padding, AppDimens.padding,
              AppDimens.padding + bottomInset,
            ),
            child: Consumer(builder: (context, ref, _) {
              final state = ref.watch(settingsViewModelProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.title(
                    getString(null, 'heading_verify_password'),
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  AppText.body(getString(null, 'description_enter_your_old_password')),
                  const SizedBox(height: AppDimens.paddingM),
                  AppTextField(
                    controller: controller,
                    hintText: getString(appStr.hintPassword, 'hint_password'),
                    obscureText: true,
                    onChanged: viewModel.updateDeletePassword,
                  ),
                  const SizedBox(height: AppDimens.paddingXL),
                  Row(
                    children: [
                      Expanded(
                        child: AppOutlinedButton(
                          text: getString(appStr.buttonCancel, 'button_cancel'),
                          onPressed: () {
                            sheetContext.goBack();
                            viewModel.dismissVerifyPassword();
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: AppFilledButton(
                          text: getString(null, 'button_verify'),
                          isLoading: state.isDeleteLoading,
                          onPressed: state.isDeleteLoading ? null : () {
                            sheetContext.goBack();
                            viewModel.submitVerifyPassword();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // ─── Delete OTP Sheet ─────────────────────────────────────────────────────

  void _showDeleteOtpBottomSheet(BuildContext context, SettingsViewModel viewModel) {
    final colors = context.colors;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppDimens.padding, AppDimens.padding, AppDimens.padding,
              AppDimens.padding + bottomInset,
            ),
            child: Consumer(builder: (context, ref, _) {
              final state = ref.watch(settingsViewModelProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.title(
                    getString(null, 'heading_enter_otp'),
                    fontWeight: FontWeight.w600,
                  ),
                  if (state.deleteOtpSentToDisplay.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingS),
                    AppText.body(state.deleteOtpSentToDisplay, color: colors.colorText),
                  ],
                  const SizedBox(height: AppDimens.paddingM),
                  AppTextField(
                    controller: controller,
                    hintText: getString(null, 'hint_otp'),
                    keyboardType: TextInputType.number,
                    onChanged: viewModel.updateDeleteOtp,
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  GestureDetector(
                    onTap: state.isDeleteLoading ? null : viewModel.resendDeleteOtp,
                    child: AppText.body(
                      getString(appStr.buttonResendOtp, 'button_resend_otp'),
                      color: colors.colorPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingXL),
                  Row(
                    children: [
                      Expanded(
                        child: AppOutlinedButton(
                          text: getString(appStr.buttonCancel, 'button_cancel'),
                          onPressed: () {
                            sheetContext.goBack();
                            viewModel.dismissDeleteOtp();
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: AppFilledButton(
                          text: getString(null, 'button_verify'),
                          isLoading: state.isDeleteLoading,
                          onPressed: state.isDeleteLoading ? null : () {
                            sheetContext.goBack();
                            viewModel.submitDeleteOtp();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  void _showLogoutBottomSheet(
    BuildContext context,
    SettingsState state,
    SettingsViewModel viewModel,
  ) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => LogoutBottomSheet(
        isLoading: state.isLogoutLoading,
        onLogout: viewModel.logout,
      ),
    );
  }

  void _showEmergencyContactsBottomSheet(
    BuildContext context,
    SettingsState state,
    SettingsViewModel viewModel,
  ) {
    final colors = context.colors;
    final screenContext = this.context;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, child) {
          final currentState = ref.watch(settingsViewModelProvider);
          final contacts = currentState.emergencyContacts;

          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.title(getString(appStr.subHeadingEmergencyContacts, 'sub_heading_emergency_contacts')),
                        IconButton(
                          icon: Icon(Icons.add, color: colors.colorPrimary),
                          onPressed: () {
                            viewModel.showAddContactSheet();
                            _showAddContactBottomSheet(screenContext, viewModel);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.paddingS),

                    // Contact list
                    if (currentState.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(AppDimens.paddingXL),
                        child: CircularProgressIndicator(),
                      ))
                    else if (contacts.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.contact_phone_outlined,
                                size: 48,
                                color: colors.colorTextHint,
                              ),
                              const SizedBox(height: AppDimens.paddingM),
                              AppText.body(
                                'No emergency contacts added',
                                color: colors.colorTextHint,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: contacts.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: colors.colorBackgroundGray,
                          ),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return _EmergencyContactTile(
                              contact: contact,
                              onEdit: () {
                                viewModel.showAddContactSheet(contact: contact);
                                _showAddContactBottomSheet(screenContext, viewModel);
                              },
                              onDelete: () => viewModel.deleteEmergencyContact(index),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddContactBottomSheet(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => _AddContactSheetContent(
        viewModel: viewModel,
        onPickContact: _pickDeviceContact,
      ),
    ).whenComplete(() {
      viewModel.hideAddContactSheet();
    });
  }

  Future<({String name, String phone})?> _pickDeviceContact() async {
    final result = await PermissionManager.instance.requestContacts();
    if (result != PermissionResult.granted) return null;

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      sorted: true,
    );

    final contactsWithPhone = contacts.where((c) => c.phones.isNotEmpty).toList();
    if (contactsWithPhone.isEmpty || !mounted) return null;

    final selected = await showModalBottomSheet<Contact>(
      context: context,
      backgroundColor: context.colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ContactPickerSheet(contacts: contactsWithPhone),
    );

    if (selected != null) {
      final name = selected.displayName;
      final phone = selected.phones.first.number.replaceAll(RegExp(r'[^\d]'), '');
      return (name: name, phone: phone);
    }
    return null;
  }
}

class _ProfileSection extends StatelessWidget {
  final String? imageUrl;
  final String fullName;
  final String phone;
  final String email;
  final VoidCallback onTap;

  const _ProfileSection({
    required this.imageUrl,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Row(
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: 32,
                  backgroundImage: imageProvider,
                ),
                placeholder: (context, url) => CircleAvatar(
                  radius: 32,
                  backgroundColor: colors.colorBackgroundGray,
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: colors.colorText,
                  ),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 32,
                  backgroundColor: colors.colorBackgroundGray,
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: colors.colorText,
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.colorBackgroundGray,
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: colors.colorText,
                ),
              ),
            const SizedBox(width: AppDimens.padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    fullName,
                    fontWeight: FontWeight.w600,
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      phone,
                      color: colors.colorText,
                    ),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      email,
                      color: colors.colorText,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.colorText,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: colors.colorText,
              size: AppDimens.iconSize,
            ),
            const SizedBox(width: AppDimens.padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    title,
                    fontWeight: FontWeight.w500,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    AppText.caption(
                      subtitle!,
                      color: colors.colorText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.colorText,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.colorBackgroundGray,
    );
  }
}

class _SelectionOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
        child: Row(
          children: [
            Expanded(
              child: AppText.body(title),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: colors.colorPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddContactSheetContent extends ConsumerStatefulWidget {
  final SettingsViewModel viewModel;
  final Future<({String name, String phone})?> Function() onPickContact;

  const _AddContactSheetContent({
    required this.viewModel,
    required this.onPickContact,
  });

  @override
  ConsumerState<_AddContactSheetContent> createState() =>
      _AddContactSheetContentState();
}

class _AddContactSheetContentState
    extends ConsumerState<_AddContactSheetContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentState = ref.watch(settingsViewModelProvider);
    if (_nameController.text != currentState.contactName) {
      _nameController.value = TextEditingValue(
        text: currentState.contactName,
        selection: TextSelection.collapsed(
          offset: currentState.contactName.length,
        ),
      );
    }
    if (_phoneController.text != currentState.contactPhone) {
      _phoneController.value = TextEditingValue(
        text: currentState.contactPhone,
        selection: TextSelection.collapsed(
          offset: currentState.contactPhone.length,
        ),
      );
    }
    final isEditing = currentState.editingContactId != null;
    final title = isEditing
        ? getString(appStr.headingUpdateEmergencyContact,
            'heading_update_emergency_contact')
        : getString(appStr.headingAddEmergencyContact,
            'heading_add_emergency_contact');

    // Auto-close on success
    ref.listen<SettingsState>(settingsViewModelProvider, (previous, next) {
      if (previous?.showAddContactBottomSheet == true &&
          !next.showAddContactBottomSheet) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }

      // Show country phone code picker from this sheet's context (not parent)
      if (next.showContactCountryPhoneCodeBottomSheet &&
          previous?.showContactCountryPhoneCodeBottomSheet != true) {
        CountryPhoneCodeBottomSheet.show(
          context,
          phoneCodeList: next.multiplePhoneCodeCountryList,
          selectedPhoneCode: next.contactCountryCode,
          onPhoneCodeSelected: (country) {
            widget.viewModel.updateContactCountryPhoneCode(country);
          },
        ).then((_) => widget.viewModel.dismissContactCountryPhoneCodeBottomSheet());
      }
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimens.padding,
          right: AppDimens.padding,
          top: AppDimens.padding,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.padding,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.title(title),
              const SizedBox(height: AppDimens.paddingXL),

              // Name field
              AppTextField(
                controller: _nameController,
                hintText: 'Name',
                textInputAction: TextInputAction.next,
                onChanged: widget.viewModel.updateContactName,
              ),
              const SizedBox(height: AppDimens.paddingM),

              // Phone field with country code picker
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Country code button — matches AppTextField fill color
                  GestureDetector(
                    onTap: () {
                      widget.viewModel.toggleContactCountryPhoneCodeBottomSheet();
                    },
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: colors.colorBackgroundGray,
                        borderRadius: BorderRadius.circular(AppDimens.buttonRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentState.contactCountryCode.isNotEmpty
                                ? currentState.contactCountryCode
                                : '+',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.colorText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: colors.colorText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: AppTextField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onChanged: widget.viewModel.updateContactPhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.paddingM),

              // Pick from contacts button
              TextButton.icon(
                onPressed: () async {
                  final picked = await widget.onPickContact();
                  if (picked != null && mounted) {
                    _nameController.text = picked.name;
                    _phoneController.text = picked.phone;
                    widget.viewModel.updateContactName(picked.name);
                    widget.viewModel.updateContactPhone(picked.phone);
                  }
                },
                icon: Icon(Icons.contacts_outlined, color: colors.colorPrimary),
                label: Text(
                  'Pick from Contacts',
                  style: TextStyle(color: colors.colorPrimary),
                ),
              ),
              const SizedBox(height: AppDimens.paddingXL),

              // Save button
              SizedBox(
                width: double.infinity,
                child: AppFilledButton(
                  text: isEditing
                      ? getString(appStr.buttonUpdate, 'button_update')
                      : getString(appStr.buttonSave, 'button_save'),
                  isLoading: currentState.isContactLoading,
                  onPressed: currentState.isContactLoading
                      ? null
                      : () => widget.viewModel.saveEmergencyContact(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  final EmergencyContactItem contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmergencyContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.colorBackgroundGray,
            child: Icon(
              Icons.person_outline,
              color: colors.colorText,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(
                  contact.name,
                  fontWeight: FontWeight.w500,
                ),
                if (contact.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AppText.caption(
                    '${contact.countryPhoneCode ?? ''} ${contact.phone}'.trim(),
                    color: colors.colorTextHint,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: colors.colorPrimary),
            onPressed: onEdit,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(AppDimens.paddingS),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: colors.colorWarning),
            onPressed: onDelete,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(AppDimens.paddingS),
          ),
        ],
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerSheet({required this.contacts});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  late List<Contact> _filteredContacts;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts
            .where((c) => c.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: Column(
            children: [
              AppTextField(
                controller: _searchController,
                hintText: 'Search contacts',
                prefixIcon: Icon(Icons.search, color: colors.colorTextHint),
                onChanged: _onSearch,
              ),
              const SizedBox(height: AppDimens.paddingM),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    final phone = contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.colorBackgroundGray,
                        child: Icon(Icons.person, color: colors.colorText, size: 20),
                      ),
                      title: AppText.body(contact.displayName),
                      subtitle: phone.isNotEmpty
                          ? AppText.caption(phone, color: colors.colorTextHint)
                          : null,
                      onTap: () => Navigator.pop(context, contact),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
