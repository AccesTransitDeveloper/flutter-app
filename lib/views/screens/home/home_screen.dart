import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/api/server_config.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../models/responses/booking/promo_code_response.dart';
import '../../../models/ride_type_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../views/widgets/app_text.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Screen - home mounted');
    final state = ref.watch(homeViewModelProvider);

    // Mode B: Approval pending screen (documents uploaded/rejected/expired)
    if (state.showApprovalScreen) {
      return SafeArea(
        child: _ApprovalPendingScreen(items: state.missingInfoItems),
      );
    }

    // Mode A: Missing information sheet at bottom, app name at top
    if (state.showMissingInfoSheet) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: AppText.heading(
                getString(null, 'app_name_short'),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _MissingInformationSheet(
              items: state.missingInfoItems,
              onItemNavigated: () {
                ref.read(homeViewModelProvider.notifier).getInformationStatus();
              },
            ),
          ],
        ),
      );
    }

    // Normal home content
    return SafeArea(
      child: _HomeContent(state: state),
    );
  }
}

/// Normal home screen content
class _HomeContent extends StatelessWidget {
  final HomeState state;

  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo/Name
            AppText.heading(
              getString(null, 'app_name_short'),
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: AppDimens.paddingXL),

            // Pickup and destination, straight on the home screen. Tapping
            // either opens the plan-ride screen, which is where the ride type
            // is now chosen too — home no longer asks for it up front.
            _SearchBar(
              pickupAddress: state.pickupAddress,
              citySetting: state.vehicleTypeResponse?.citySetting,
              rideTypeItems: state.rideTypeItems,
            ),

            // Location permission banner
            if (state.isLocationPermissionDenied) ...[
              const SizedBox(height: AppDimens.paddingXL),
              const _LocationPermissionBanner(),
            ],

            // Promo offers carousel
            if (state.promoOffersList.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingXL),
              _PromoSlider(promos: state.promoOffersList),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mode B: Approval pending / declined screen
class _ApprovalPendingScreen extends StatelessWidget {
  final List<MissingInfoItem> items;

  const _ApprovalPendingScreen({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = items.isNotEmpty ? items.first.title : '';
    final description = items.isNotEmpty ? items.first.description : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 100,
              color: colors.colorWarning,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            AppText.title(
              title,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingM),
            AppText.body(
              description,
              textAlign: TextAlign.center,
              color: colors.colorText.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mode A: Missing information bottom sheet
class _MissingInformationSheet extends StatelessWidget {
  final List<MissingInfoItem> items;
  final VoidCallback? onItemNavigated;

  const _MissingInformationSheet({required this.items, this.onItemNavigated});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tertiary color top indicator bar
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: colors.colorWarning,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
          // Header with icon, title and subtitle
          Padding(
            padding: const EdgeInsets.all(AppDimens.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.colorWarning,
                    ),
                    const SizedBox(width: 10),
                    AppText.title(
                      '${getString(appStr.headingRequiredActions, 'heading_required_actions')} (${items.length})',
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingXS),
                AppText.body(
                  getString(appStr.descriptionBookWhenResolved, 'description_book_when_resolved'),
                  color: colors.colorPrimary,
                ),
              ],
            ),
          ),
          // Items list
          ...items.map((item) => _MissingInfoItemTile(item: item, onNavigated: onItemNavigated)),
          const SizedBox(height: AppDimens.paddingM),
        ],
      ),
    );
  }
}

/// Individual missing information item tile
class _MissingInfoItemTile extends StatelessWidget {
  final MissingInfoItem item;
  final VoidCallback? onNavigated;

  const _MissingInfoItemTile({required this.item, this.onNavigated});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: item.isEnabled ? () => _onTap(context) : null,
      child: Opacity(
        opacity: item.isEnabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimens.padding),
              AppText.title(
                item.title,
                fontWeight: FontWeight.w500,
              ),
              AppText.body(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: colors.colorText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: colors.colorText.withValues(alpha: 0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    switch (item.id) {
      case 1:
        await context.navigateToProfile();
        break;
      case 2:
        await context.navigateToDocuments();
        break;
      case 3:
        // Gender selection — navigate to profile
        await context.navigateToProfile();
        break;
    }
    onNavigated?.call();
  }
}

// Promo offers horizontal carousel
class _PromoSlider extends StatelessWidget {
  final List<PromoCodes> promos;

  const _PromoSlider({required this.promos});

  @override
  Widget build(BuildContext context) {
    final sliderHeight = MediaQuery.of(context).size.width / 2.4;

    return SizedBox(
      height: sliderHeight,
      child: PageView.builder(
        itemCount: promos.length,
        controller: PageController(viewportFraction: promos.length > 1 ? 0.9 : 1.0),
        itemBuilder: (context, index) {
          final promo = promos[index];
          final imageUrl = promo.bannerImageUrl != null
              ? ServerConfig.getFullImageUrl(promo.bannerImageUrl)
              : null;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: promos.length > 1 ? AppDimens.paddingXS : 0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: sliderHeight,
                      placeholder: (context, url) => Container(
                        color: context.colors.colorBackgroundGray,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: context.colors.colorBackgroundGray,
                      ),
                    )
                  : Container(
                      color: context.colors.colorBackgroundGray,
                    ),
            ),
          );
        },
      ),
    );
  }
}

// Location permission banner - shown when permission is denied
class _LocationPermissionBanner extends StatelessWidget {
  const _LocationPermissionBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.padding),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C518),
        borderRadius: BorderRadius.circular(AppDimens.paddingM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title(
            getString(null, 'description_avoid_pickup_confusion'),
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          const SizedBox(height: AppDimens.paddingM),
          GestureDetector(
            onTap: () => openAppSettings(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.padding,
                vertical: AppDimens.paddingS,
              ),
              decoration: BoxDecoration(
                color: colors.colorButtonBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText.body(
                getString(null, 'button_share_location'),
                color: colors.colorButtonText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Search Bar Widget
class _SearchBar extends StatelessWidget {
  final DestinationAddress? pickupAddress;
  final CitySetting? citySetting;
  final List<RideTypeItem> rideTypeItems;

  const _SearchBar({
    this.pickupAddress,
    this.citySetting,
    this.rideTypeItems = const [],
  });

  void _openPlanRide(BuildContext context) => context.navigateToPlanRide(
        pickupAddress: pickupAddress,
        // No ride type is chosen up front any more — the plan-ride screen picks
        // it from the chips beside "for me / for other".
        citySetting: citySetting,
        rideTypeItems: rideTypeItems,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pickupLabel = pickupAddress?.address ??
        pickupAddress?.title ??
        'Enter pickup location';

    return GestureDetector(
      onTap: () => _openPlanRide(context),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.padding),
        ),
        child: Column(
          children: [
            _AddressRow(
              icon: Icons.trip_origin,
              iconColor: colors.colorPrimary,
              text: pickupLabel,
              isPlaceholder: pickupAddress == null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.paddingS,
              ),
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.colorBackground,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _AddressRow(
                    icon: Icons.place_outlined,
                    iconColor: colors.colorWarning,
                    text: 'Where to?',
                    isPlaceholder: true,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                // The "Later" shortcut lived on the old single-line search
                // pill; keep it reachable now that the pill is a two-row card.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: colors.colorButtonBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: colors.colorButtonText,
                        size: 14,
                      ),
                      const SizedBox(width: AppDimens.paddingXS),
                      AppText.caption(
                        getString(null, 'description_later'),
                        color: colors.colorButtonText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of the home pickup/destination card.
class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool isPlaceholder;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: AppDimens.paddingM),
        Expanded(
          child: AppText.body(
            text,
            color: isPlaceholder ? colors.colorTextHint : colors.colorText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Suggestions Section - displays ride type items
