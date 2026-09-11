import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../models/responses/address/address_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/saved_places_viewmodel.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_text_field.dart';
import '../../../views/widgets/app_toolbar.dart';

class AddSavedPlaceScreen extends ConsumerStatefulWidget {
  final SavedAddress? editingAddress;
  final int? addressType;
  final DestinationAddress? selectedLocation;

  const AddSavedPlaceScreen({
    super.key,
    this.editingAddress,
    this.addressType,
    this.selectedLocation,
  });

  @override
  ConsumerState<AddSavedPlaceScreen> createState() => _AddSavedPlaceScreenState();
}

class _AddSavedPlaceScreenState extends ConsumerState<AddSavedPlaceScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMode();
    });
  }

  void _initializeMode() {
    final viewModel = ref.read(savedPlacesViewModelProvider.notifier);

    if (widget.editingAddress != null) {
      viewModel.enterEditMode(widget.editingAddress!);
      _nicknameController.text = widget.editingAddress!.title ?? '';
    } else if (widget.addressType != null) {
      viewModel.enterAddMode(widget.addressType!);
      // Set default nickname for Home/Work
      if (widget.addressType == AddressType.home) {
        _nicknameController.text = getString(appStr.descriptionHome, 'description_home');
      } else if (widget.addressType == AddressType.work) {
        _nicknameController.text = getString(appStr.descriptionWork, 'description_work');
      }
      // Set selected location if provided
      if (widget.selectedLocation != null) {
        viewModel.setSelectedLocation(widget.selectedLocation!);
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _onNicknameChanged(String value) {
    ref.read(savedPlacesViewModelProvider.notifier).setNickname(value);
  }

  void _onClearNickname() {
    _nicknameController.clear();
    ref.read(savedPlacesViewModelProvider.notifier).setNickname('');
  }

  Future<void> _onAddressTap() async {
    final state = ref.read(savedPlacesViewModelProvider);
    // Pass current selected location as initial address for editing
    final result = await context.navigateToSelectLocation(
      initialAddress: state.selectedLocation,
    );
    if (result != null) {
      ref.read(savedPlacesViewModelProvider.notifier).setSelectedLocation(result);
    }
  }

  Future<void> _onSavePlace() async {
    final success = await ref.read(savedPlacesViewModelProvider.notifier).saveAddress();
    if (success && mounted) {
      context.goBack();
    }
  }

  void _onBackPressed() {
    ref.read(savedPlacesViewModelProvider.notifier).exitAddEditMode();
    context.goBack();
  }

  /// Check if the current address type is Home or Work
  /// Home and Work titles are not editable
  bool _isHomeOrWorkAddress(SavedPlacesState state) {
    final addressType = state.selectedAddressType ?? widget.addressType;
    return addressType == AddressType.home || addressType == AddressType.work;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(savedPlacesViewModelProvider);

    // Listen for errors
    ref.listen<SavedPlacesState>(savedPlacesViewModelProvider, (previous, next) {
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
            AppToolbar(
              title: state.isEditing
                  ? getString(appStr.headingEditSavedPlace, 'heading_edit_saved_place')
                  : getString(appStr.headingAddSavedPlace, 'heading_add_saved_place'),
              onBack: _onBackPressed,
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nickname field
                    // Home and Work titles are shown but not editable
                    AppText.body(
                      getString(appStr.descriptionLocationNickname, 'description_location_nickname'),
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    AppTextField(
                      controller: _nicknameController,
                      hintText: getString(appStr.hintLocationNicknameExample, 'hint_location_nickname_example'),
                      onChanged: _isHomeOrWorkAddress(state) ? null : _onNicknameChanged,
                      readOnly: _isHomeOrWorkAddress(state),
                      suffixIcon: !_isHomeOrWorkAddress(state) && _nicknameController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: colors.colorText,
                                size: 20,
                              ),
                              onPressed: _onClearNickname,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),

                    // Address selector
                    _buildAddressSelector(context, state),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: AppFilledButton(
                text: getString(appStr.buttonSavePlace, 'button_save_place'),
                onPressed: _onSavePlace,
                isLoading: state.isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSelector(BuildContext context, SavedPlacesState state) {
    final colors = context.colors;
    final hasAddress = state.selectedLocation != null;

    return InkWell(
      onTap: _onAddressTap,
      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.colorText.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    getString(appStr.descriptionAddress, 'description_address'),
                    fontWeight: FontWeight.w500,
                  ),
                  if (hasAddress) ...[
                    const SizedBox(height: 4),
                    AppText.caption(
                      state.selectedLocation!.address ?? '',
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
              size: AppDimens.iconSize,
            ),
          ],
        ),
      ),
    );
  }

}
