import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/responses/address/address_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/saved_places_viewmodel.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';

class SavedPlacesScreen extends ConsumerStatefulWidget {
  final bool isForAddressSelect;

  const SavedPlacesScreen({
    super.key,
    this.isForAddressSelect = false,
  });

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedPlacesViewModelProvider);

    // Listen for success messages to show snackbar
    ref.listen<SavedPlacesState>(savedPlacesViewModelProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        context.showSnackBar(next.successMessage!);
        ref.read(savedPlacesViewModelProvider.notifier).clearSuccessMessage();
      }
      if (next.error != null && next.error != previous?.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(savedPlacesViewModelProvider.notifier).clearError();
      }
    });

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            AppToolbar(title: getString(appStr.headingSavedPlaces, 'heading_saved_places')),

            // Content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SavedPlacesState state) {
    final colors = context.colors;
    // Indent = icon size + spacing after icon
    const dividerIndent = AppDimens.iconSize + AppDimens.padding;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      children: [
        // Home address
        _buildHomeWorkItem(
          context,
          icon: Icons.home_outlined,
          title: getString(appStr.descriptionHome, 'description_home'),
          address: state.homeAddress,
          addressType: AddressType.home,
        ),
        Divider(color: colors.colorText.withValues(alpha: 0.2), height: 1, indent: dividerIndent),

        // Work address
        _buildHomeWorkItem(
          context,
          icon: Icons.work_outline,
          title: state.workAddress != null
              ? getString(appStr.descriptionWork, 'description_work')
              : getString(appStr.descriptionAddWork, 'description_add_work'),
          address: state.workAddress,
          addressType: AddressType.work,
        ),
        Divider(color: colors.colorText.withValues(alpha: 0.2), height: 1, indent: dividerIndent),

        // Other saved places
        ...state.otherAddresses.map((address) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOtherAddressItem(context, address),
                Divider(color: colors.colorText.withValues(alpha: 0.2), height: 1, indent: dividerIndent),
              ],
            )),

        // Add a new place button
        _buildAddNewPlaceButton(context),
      ],
    );
  }

  Widget _buildHomeWorkItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required SavedAddress? address,
    required int addressType,
  }) {
    final hasAddress = address != null;

    return _SavedPlaceItemView(
      icon: icon,
      title: hasAddress ? (address.title ?? title) : title,
      subtitle: hasAddress ? address.address : null,
      showMenu: hasAddress,
      onTap: () => _onHomeWorkTap(address, addressType),
      onMenuSelected: hasAddress ? (value) => _onMenuItemSelected(value, address) : null,
    );
  }

  Widget _buildOtherAddressItem(BuildContext context, SavedAddress address) {
    return _SavedPlaceItemView(
      icon: Icons.star_outline,
      title: address.title ?? getString(appStr.descriptionSavedPlace, 'description_saved_place'),
      subtitle: address.address,
      showMenu: true,
      onTap: () => _onOtherAddressTap(address),
      onMenuSelected: (value) => _onMenuItemSelected(value, address),
    );
  }

  Widget _buildAddNewPlaceButton(BuildContext context) {
    return _SavedPlaceItemView(
      icon: Icons.add,
      title: getString(appStr.buttonAddNewPlace, 'button_add_new_place'),
      onTap: _onAddNewPlace,
    );
  }

  void _onHomeWorkTap(SavedAddress? address, int addressType) {
    if (widget.isForAddressSelect) {
      // Selection mode - return address if exists
      if (address != null) {
        context.goBack(address.toDestinationAddress());
      }
    } else {
      // Management mode - only allow adding if no address
      if (address == null) {
        context.navigateToAddSavedPlace(addressType: addressType);
      }
      // If has address, do nothing - edit only via popup menu
    }
  }

  void _onMenuItemSelected(String value, SavedAddress address) {
    switch (value) {
      case 'edit':
        _onEditAddress(address);
        break;
      case 'delete':
        _showDeleteConfirmation(address);
        break;
    }
  }

  void _onOtherAddressTap(SavedAddress address) {
    if (widget.isForAddressSelect) {
      // Selection mode - return address
      context.goBack(address.toDestinationAddress());
    }
    // Management mode - do nothing, edit only via popup menu
  }

  void _onEditAddress(SavedAddress address) {
    context.navigateToAddSavedPlace(address: address);
  }

  Future<void> _onAddNewPlace() async {
    final result = await context.navigateToSelectLocation();
    if (result != null && mounted) {
      // Navigate to add-saved-place with the selected location
      context.navigateToAddSavedPlace(
        addressType: AddressType.other,
        selectedLocation: result,
      );
    }
  }

  void _showDeleteConfirmation(SavedAddress address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: AppText.body(getString(appStr.headingDeleteAddress, 'heading_delete_address'), fontWeight: FontWeight.w600),
        content: AppText.body(getString(appStr.descriptionConfirmDeleteAddressMessage, 'description_confirm_delete_address_message')),
        actions: [
          TextButton(
            onPressed: () => dialogContext.goBack(),
            child: AppText.body(getString(appStr.buttonCancel, 'button_cancel')),
          ),
          TextButton(
            onPressed: () {
              dialogContext.goBack();
              if (address.id != null) {
                ref.read(savedPlacesViewModelProvider.notifier).deleteAddress(address.id!);
              }
            },
            child: AppText.body(getString(appStr.descriptionDelete, 'description_delete')),
          ),
        ],
      ),
    );
  }

}

/// Reusable item view for saved places list
class _SavedPlaceItemView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showMenu;
  final VoidCallback? onTap;
  final ValueChanged<String>? onMenuSelected;

  const _SavedPlaceItemView({
    required this.icon,
    required this.title,
    this.subtitle,
    this.showMenu = false,
    this.onTap,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
        child: Row(
          children: [
            Icon(icon, size: AppDimens.iconSize, color: colors.colorText),
            const SizedBox(width: AppDimens.padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    title,
                    fontWeight: FontWeight.w500,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
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
            if (showMenu)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colors.colorText,
                  size: AppDimens.iconSize,
                ),
                onSelected: onMenuSelected,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: AppText.body(getString(appStr.buttonEdit, 'button_edit')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: AppText.body(getString(appStr.descriptionDelete, 'description_delete')),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
