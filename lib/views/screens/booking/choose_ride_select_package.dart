import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/booking/accessibility_preference.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../item/rental_package_item.dart';
import '../../widgets/app_text.dart';

/// Segment 1 sub-step: Rental Package Selection
///
/// Replaces the vehicle list when a rental vehicle is selected and user clicks "Choose".
/// Shows the selected vehicle summary at top + list of rental packages.
class ChooseRideSelectPackage extends StatelessWidget {
  final NormalVehicles vehicle;
  final List<RentalPack> packageList;
  final int selectedPackageIndex;
  final String? currencySign;
  final CountrySettings? countrySetting;
  final List<CustomPrice>? customPrices;
  final List<AccessibilityPreference>? accessibilities;
  final List<String>? selectedAccessibilityIds;
  final ScrollController scrollController;
  final DraggableScrollableController? sheetController;
  final ValueChanged<int> onPackageSelected;
  final VoidCallback onBack;

  const ChooseRideSelectPackage({
    super.key,
    required this.vehicle,
    required this.packageList,
    required this.selectedPackageIndex,
    required this.currencySign,
    required this.countrySetting,
    this.customPrices,
    this.accessibilities,
    this.selectedAccessibilityIds,
    required this.scrollController,
    this.sheetController,
    required this.onPackageSelected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Header with back button
        _DraggableHeader(
          sheetController: sheetController,
          scrollController: scrollController,
          child: _buildHeader(context, colors),
        ),

        // Scrollable content
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Vehicle summary
              SliverToBoxAdapter(
                child: _buildVehicleSummary(colors),
              ),

              // Package list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final package = packageList[index];
                      return RentalPackageItem(
                        index: index,
                        package: package,
                        isSelected: selectedPackageIndex == index,
                        currencySign: currencySign,
                        countrySetting: countrySetting,
                        customPrices: customPrices,
                        accessibilities: accessibilities,
                        selectedAccessibilityIds: selectedAccessibilityIds,
                        onTap: () => onPackageSelected(index),
                      );
                    },
                    childCount: packageList.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppColorPalette colors) {
    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: AppDimens.paddingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.colorText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title row with back button
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingS,
            vertical: AppDimens.paddingS,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back,
                  color: colors.colorText,
                ),
              ),
              Expanded(
                child: AppText.title(
                  'Choose Package',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Divider
        Divider(
          height: 1,
          color: colors.colorText.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildVehicleSummary(AppColorPalette colors) {
    final vehicleDetail = vehicle.vehicleTypeDetail;
    final name = vehicleDetail?.name ?? 'Vehicle';
    final imageUrl = vehicleDetail?.imageUrl != null
        ? ServerConfig.getFullImageUrl(vehicleDetail!.imageUrl)
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.padding),
      child: Row(
        children: [
          // Small vehicle image
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: colors.colorBackground,
              borderRadius: BorderRadius.circular(AppDimens.buttonRadiusSmall),
            ),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Icon(
                      Icons.directions_car,
                      color: colors.colorText,
                      size: 24,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.directions_car,
                      color: colors.colorText,
                      size: 24,
                    ),
                  )
                : Icon(
                    Icons.directions_car,
                    color: colors.colorText,
                    size: 24,
                  ),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.colorText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draggable header widget that controls the sheet via drag gestures
class _DraggableHeader extends StatefulWidget {
  final DraggableScrollableController? sheetController;
  final ScrollController scrollController;
  final Widget child;

  const _DraggableHeader({
    required this.sheetController,
    required this.scrollController,
    required this.child,
  });

  @override
  State<_DraggableHeader> createState() => _DraggableHeaderState();
}

class _DraggableHeaderState extends State<_DraggableHeader> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: widget.child,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final controller = widget.sheetController;
    if (controller == null) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final delta = -details.delta.dy / screenHeight;
    final newSize = (controller.size + delta).clamp(0.45, 0.9);

    controller.jumpTo(newSize);
  }

  void _onDragEnd(DragEndDetails details) {
    final controller = widget.sheetController;
    if (controller == null) return;

    final velocity = details.primaryVelocity ?? 0;
    final currentSize = controller.size;

    double targetSize;
    if (velocity < -500) {
      targetSize = 0.9;
    } else if (velocity > 500) {
      targetSize = 0.45;
    } else {
      targetSize = currentSize > 0.675 ? 0.9 : 0.45;
    }

    controller.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    if (targetSize == 0.45 && widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
}
