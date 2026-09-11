import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/select_location_viewmodel.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';

class SelectLocationScreen extends ConsumerStatefulWidget {
  /// Initial address to edit (if provided, camera will move to this location)
  final DestinationAddress? initialAddress;

  /// Country code to restrict autocomplete results (e.g. "US", "IN")
  final String? countryCode;

  const SelectLocationScreen({
    super.key,
    this.initialAddress,
    this.countryCode,
  });

  @override
  ConsumerState<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends ConsumerState<SelectLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Map manager - created once per screen instance
  late final MapInterface _mapManager;
  late final SelectLocationParams _params;

  @override
  void initState() {
    super.initState();

    // Create map manager instance for this screen
    _mapManager = ref.read(mapManagerProvider)();
    _params = SelectLocationParams(
      mapManager: _mapManager,
      countryCode: widget.countryCode,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set initial address in ViewModel if provided
      if (widget.initialAddress != null) {
        ref.read(selectLocationViewModelProvider(_params).notifier).setInitialAddress(widget.initialAddress!);
      }
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapManager.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(selectLocationViewModelProvider(_params).notifier).searchPlaces(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(selectLocationViewModelProvider(_params).notifier).searchPlaces('');
  }

  Future<void> _onPlaceSelected(DestinationAddress place) async {
    final viewModel = ref.read(selectLocationViewModelProvider(_params).notifier);
    final details = await viewModel.getPlaceDetails(place);
    if (details != null && mounted) {
      context.goBack(details);
    }
  }

  void _onSetLocationOnMap() {
    ref.read(selectLocationViewModelProvider(_params).notifier).enterMapSelectionMode();
  }

  void _onExitMapMode() {
    ref.read(selectLocationViewModelProvider(_params).notifier).exitMapSelectionMode();
    _searchFocusNode.requestFocus();
  }

  void _onConfirmMapSelection() {
    final viewModel = ref.read(selectLocationViewModelProvider(_params).notifier);
    final address = viewModel.confirmMapSelection();
    if (address != null && mounted) {
      context.goBack(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selectLocationViewModelProvider(_params));

    if (state.isMapSelectionMode) {
      return _buildMapSegment(context, state);
    } else {
      return _buildSearchSegment(context, state);
    }
  }

  Widget _buildSearchSegment(BuildContext context, SelectLocationState state) {
    final colors = context.colors;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.goBack(),
                    child: Icon(
                      Icons.arrow_back,
                      color: colors.colorText,
                      size: AppDimens.iconSize,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: colors.colorBackgroundGray,
                        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              style: TextStyle(
                                color: colors.colorText,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: getString(appStr.hintSearchLocation, 'hint_search_location'),
                                hintStyle: TextStyle(
                                  color: colors.colorText,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppDimens.paddingM,
                                ),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: _onClearSearch,
                              child: Icon(
                                Icons.close,
                                color: colors.colorText,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildSearchContent(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context, SelectLocationState state) {
    final colors = context.colors;
    final searchResults = state.searchResults;
    final viewModel = ref.read(selectLocationViewModelProvider(_params).notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      children: [
        // Loading indicator for search
        if (state.isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimens.paddingM),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Search results list
        if (!state.isSearching)
          ...searchResults.map((address) {
            final distance = viewModel.calculateDistanceMiles(address);
            final distanceText = distance != null ? '${distance.toStringAsFixed(1)} mi' : null;

            return _AddressListItem(
              icon: Icons.location_on_outlined,
              title: address.title ?? address.address ?? '',
              subtitle: address.city ?? address.address,
              distance: distanceText,
              onTap: () => _onPlaceSelected(address),
            );
          }),

        // Divider
        if (!state.isSearching && searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
            child: Divider(color: colors.colorText.withValues(alpha: 0.2)),
          ),

        // Set location on map
        _AddressListItem(
          icon: Icons.location_on_outlined,
          title: getString(appStr.buttonSetLocationOnMap, 'button_set_location_on_map'),
          onTap: _onSetLocationOnMap,
        ),
      ],
    );
  }

  Widget _buildMapSegment(BuildContext context, SelectLocationState state) {
    final colors = context.colors;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final mapAddress = state.mapSelectionAddress;
    final addressText = mapAddress?.title ?? mapAddress?.address ?? '';
    final isLoading = state.isLoadingMapAddress;

    return AppScaffold(
      body: Stack(
        children: [
          // Layer 1: Map (full screen)
          Positioned.fill(
            child: MapHost(manager: _mapManager),
          ),

          // Layer 2: Center pin
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 100 + bottomPadding,
            child: IgnorePointer(
              child: Center(
                child: Image.asset(
                  'assets/images/ic_set_location.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.location_on,
                    color: colors.colorPrimary,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // Layer 3: Search bar at top (read-only, tappable)
          Positioned(
            top: topPadding + AppDimens.padding,
            left: AppDimens.padding,
            right: AppDimens.padding,
            child: GestureDetector(
              onTap: _onExitMapMode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.padding,
                  vertical: AppDimens.paddingM,
                ),
                decoration: BoxDecoration(
                  color: colors.colorBackground,
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  boxShadow: [
                    BoxShadow(
                      color: colors.colorText.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: colors.colorText,
                      size: AppDimens.iconSize,
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: AppText.body(
                        _searchController.text.isNotEmpty
                            ? _searchController.text
                            : getString(appStr.hintSearchLocation, 'hint_search_location'),
                        color: _searchController.text.isNotEmpty
                            ? colors.colorText
                            : colors.colorText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Layer 4: My location button
          Positioned(
            right: AppDimens.padding,
            bottom: 180 + bottomPadding,
            child: GestureDetector(
              onTap: () {
                ref.read(selectLocationViewModelProvider(_params).notifier).moveToCurrentLocation();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.colorBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.colorText.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location,
                  color: colors.colorText,
                  size: AppDimens.iconSize,
                ),
              ),
            ),
          ),

          // Layer 5: Bottom card with address and Done button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.padding,
                AppDimens.padding,
                AppDimens.padding,
                AppDimens.padding + bottomPadding,
              ),
              decoration: BoxDecoration(
                color: colors.colorBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.colorText.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address display
                  Container(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    decoration: BoxDecoration(
                      color: colors.colorBackgroundGray,
                      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: colors.colorPrimary,
                          size: AppDimens.iconSize,
                        ),
                        const SizedBox(width: AppDimens.paddingM),
                        Expanded(
                          child: isLoading
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.colorText,
                                      ),
                                    ),
                                    const SizedBox(width: AppDimens.paddingS),
                                    AppText.body(
                                      getString(appStr.descriptionGettingAddress, 'description_getting_address'),
                                      color: colors.colorText,
                                    ),
                                  ],
                                )
                              : AppText.body(
                                  addressText.isNotEmpty
                                      ? addressText
                                      : getString(appStr.descriptionMoveMapToSelect, 'description_move_map_to_select'),
                                  color: addressText.isNotEmpty
                                      ? colors.colorText
                                      : colors.colorText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.padding),

                  // Done button
                  AppFilledButton(
                    text: getString(appStr.buttonDone, 'button_done'),
                    onPressed: addressText.isNotEmpty && !isLoading
                        ? _onConfirmMapSelection
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? distance;
  final VoidCallback onTap;

  const _AddressListItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.distance,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.colorBackgroundGray,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: colors.colorText),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    title,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            if (distance != null) ...[
              const SizedBox(width: AppDimens.paddingS),
              AppText.caption(
                distance!,
                color: colors.colorText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
