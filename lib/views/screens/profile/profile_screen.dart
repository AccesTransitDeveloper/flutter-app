import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/api/server_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/responses/auth/entity_detail_response.dart';
import '../../../viewmodels/edit_profile_viewmodel.dart';
import '../../../viewmodels/profile_viewmodel.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';
import '../../bottomsheets/image_picker_bottom_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _navigateToEdit(EditProfileField field) async {
    final result = await context.navigateToEditProfile<bool>(field);
    if (result == true) {
      // Refresh profile data after successful update
      ref.read(profileViewModelProvider.notifier).refreshProfile();
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied && mounted) {
      _showPermissionDeniedDialog('Camera');
    }
    return false;
  }

  Future<bool> _requestStoragePermission() async {
    // image_picker uses PHPickerViewController on iOS 14+ which handles
    // its own permissions internally — no explicit check needed.
    return true;
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'Please enable $permissionName permission in settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await ImagePickerBottomSheet.show(context);
    if (source == null) return;

    if (source == ImagePickerSource.camera) {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission || !mounted) return;
    } else {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission || !mounted) return;
    }

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source == ImagePickerSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final success = await ref
          .read(profileViewModelProvider.notifier)
          .uploadProfilePicture(pickedFile.path);

      if (mounted) {
        final state = ref.read(profileViewModelProvider);
        if (success) {
          if (state.successMessage?.isNotEmpty == true) {
            context.showSnackBar(state.successMessage!);
          }
        } else {
          if (state.error?.isNotEmpty == true) {
            context.showErrorSnackBar(state.error!);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(profileViewModelProvider);
    final entity = state.entity;

    // Get full image URL
    final imageUrl = entity?.imageUrl != null && entity!.imageUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(entity.imageUrl)
        : null;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingProfile, 'heading_profile'),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppDimens.paddingM),
                    // Profile Image with edit button
                    Center(
                      child: Stack(
                        children: [
                          if (state.isUploadingImage)
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: colors.colorBackgroundGray,
                              child: const CircularProgressIndicator(),
                            )
                          else if (imageUrl != null)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                radius: 50,
                                backgroundImage: imageProvider,
                              ),
                              placeholder: (context, url) => CircleAvatar(
                                radius: 50,
                                backgroundColor: colors.colorBackgroundGray,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: colors.colorText,
                                ),
                              ),
                              errorWidget: (context, url, error) => CircleAvatar(
                                radius: 50,
                                backgroundColor: colors.colorBackgroundGray,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: colors.colorText,
                                ),
                              ),
                            )
                          else
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: colors.colorBackgroundGray,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: colors.colorText,
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: state.isUploadingImage ? null : _pickImage,
                              child: Container(
                                padding:
                                    const EdgeInsets.all(AppDimens.paddingXS),
                                decoration: BoxDecoration(
                                  color: colors.colorPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: AppDimens.iconSizeSmall,
                                  color: colors.colorButtonText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    // Profile Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.padding),
                      child: Column(
                        children: [
                          _ProfileField(
                            label: getString(appStr.headingName, 'heading_name'),
                            value: state.fullName,
                            onTap: () => _navigateToEdit(EditProfileField.name),
                          ),
                          const Divider(height: 1),
                          _ProfileField(
                            label: getString(appStr.headingGender, 'heading_gender'),
                            value: state.gender,
                            onTap: () =>
                                _navigateToEdit(EditProfileField.gender),
                          ),
                          const Divider(height: 1),
                          _ProfileField(
                            label: getString(appStr.descriptionPhone, 'description_phone'),
                            value: state.phoneNumber,
                            onTap: () =>
                                _navigateToEdit(EditProfileField.phone),
                          ),
                          const Divider(height: 1),
                          _ProfileField(
                            label: getString(appStr.descriptionEmail, 'description_email'),
                            value: state.email,
                            onTap: () =>
                                _navigateToEdit(EditProfileField.email),
                          ),
                        ],
                      ),
                    ),
                    // Corporate Details Section
                    if (state.isCorporateUser && state.corporateList.isNotEmpty)
                      _CorporateSection(corporateList: state.corporateList),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProfileField({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.padding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(
                    label,
                    color: colors.colorText,
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  AppText.body(value),
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

class _CorporateSection extends StatelessWidget {
  final List<TypeIdDetails> corporateList;

  const _CorporateSection({required this.corporateList});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimens.paddingXL),
          AppText.title(
            getString(appStr.subHeadingCorporate, 'sub_heading_corporate'),
            fontWeight: FontWeight.w600,
          ),
          ...corporateList.map((detail) {
            final imgUrl = detail.imageUrl;
            final hasImage = imgUrl != null && imgUrl.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(top: AppDimens.paddingM),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: ServerConfig.getFullImageUrl(imgUrl),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              width: 40,
                              height: 40,
                              color: colors.colorBackgroundGray,
                              child: Icon(Icons.business, size: 20, color: colors.colorText),
                            ),
                            errorWidget: (_, _, _) => Container(
                              width: 40,
                              height: 40,
                              color: colors.colorBackgroundGray,
                              child: Icon(Icons.business, size: 20, color: colors.colorText),
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            color: colors.colorBackgroundGray,
                            child: Icon(Icons.business, size: 20, color: colors.colorText),
                          ),
                  ),
                  const SizedBox(width: AppDimens.padding),
                  Expanded(
                    child: AppText.body(
                      detail.name ?? '',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
