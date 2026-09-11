import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/utils/invoice_util.dart';
import '../../models/invoice.dart';
import '../../models/responses/booking/accessibility_preference.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../../core/theme/app_theme.dart';
import '../../views/widgets/app_button.dart';
import '../../views/widgets/app_text.dart';

class FareEstimationBottomSheet extends StatelessWidget {
  final InvoiceDetail? invoiceDetail;
  final String currencySign;
  final int currencyDirection;
  final int decimalPointValue;
  final int? distanceUnit;
  final String? vehiclePriceId;
  final List<CustomPrice>? customPrices;
  final List<AccessibilityPreference>? accessibilities;
  final List<String>? selectedAccessibilityIds;

  const FareEstimationBottomSheet({
    super.key,
    required this.invoiceDetail,
    required this.currencySign,
    required this.currencyDirection,
    required this.decimalPointValue,
    this.distanceUnit,
    this.vehiclePriceId,
    this.customPrices,
    this.accessibilities,
    this.selectedAccessibilityIds,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final invoiceUtil = InvoiceUtil(
      currencyDirection: currencyDirection,
      currencySign: currencySign,
      decimalPointValue: decimalPointValue,
      distanceUnit: distanceUnit,
    );

    // Convert customPrices to accessibilityList (id → title mapping)
    final accessibilityList = customPrices
            ?.map((p) => MapEntry(p.id ?? '', p.title ?? ''))
            .toList() ??
        [];

    // Transform invoice detail: filter accessibility and map price titles
    final transformedInvoiceDetail = _transformInvoiceDetail(
      invoiceDetail,
      selectedAccessibilityIds,
      customPrices,
      accessibilities,
    );

    // Show accessibility prices only when user has selected some
    final hasSelectedAccessibility = selectedAccessibilityIds?.isNotEmpty == true;

    final invoiceList = invoiceUtil.getInvoiceElements(
      invoiceData: transformedInvoiceDetail,
      isFareEstimate: !hasSelectedAccessibility,
      accessibilityList: accessibilityList,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.padding,
              AppDimens.padding,
              AppDimens.padding,
              AppDimens.paddingS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText.title('Fare Estimation'),
                const SizedBox(height: AppDimens.paddingS),
                AppText.caption(
                  'This is just an estimated time. Actual fare may vary slightly based on traffic or discount',
                  color: colors.colorText,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.paddingS),

          // Divider
          Divider(color: colors.colorBackgroundGray, height: 1),

          // Invoice list
          Flexible(
            child: invoiceList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppDimens.padding),
                    child: Center(
                      child: AppText.body(
                        'No fare details available',
                        color: colors.colorText,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.padding,
                      vertical: AppDimens.paddingM,
                    ),
                    itemCount: invoiceList.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimens.paddingM),
                    itemBuilder: (context, index) {
                      return _InvoiceItem(
                        invoice: invoiceList[index],
                      );
                    },
                  ),
          ),

          // Divider
          Divider(color: colors.colorBackgroundGray, height: 1),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(AppDimens.padding),
            child: Row(
              children: [
                if (vehiclePriceId != null && vehiclePriceId!.isNotEmpty)
                  Expanded(
                    child: AppOutlinedButton(
                      text: 'View Cancellation Policy',
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/cancellation-policy/$vehiclePriceId');
                      },
                    ),
                  ),
                if (vehiclePriceId != null && vehiclePriceId!.isNotEmpty)
                  const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: AppFilledButton(
                    text: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Transform invoice detail:
  /// - Filter accessibilityPrices to only include selected ones
  /// - Map additionalPrices titles from customPrices
  /// - Map accessibilityPrices titles from accessibilities
  InvoiceDetail? _transformInvoiceDetail(
    InvoiceDetail? invoiceDetail,
    List<String>? selectedIds,
    List<CustomPrice>? customPrices,
    List<AccessibilityPreference>? accessibilities,
  ) {
    if (invoiceDetail == null) return null;

    // Filter accessibilityPrices to only include items where chargeId is in selectedIds
    final filteredAccessibilityPrices = (selectedIds == null || selectedIds.isEmpty)
        ? invoiceDetail.accessibilityPrices
        : invoiceDetail.accessibilityPrices
            ?.where((price) => selectedIds.contains(price.chargeId))
            .toList();

    // Map additionalPrices titles from customPrices
    final mappedAdditionalPrices = _mapPriceTitles(
      invoiceDetail.additionalPrices,
      customPrices,
    );

    // Map accessibilityPrices titles from accessibilities
    final mappedAccessibilityPrices = _mapAccessibilityPriceTitles(
      filteredAccessibilityPrices,
      accessibilities,
    );

    return InvoiceDetail(
      distance: invoiceDetail.distance,
      time: invoiceDetail.time,
      waitingTime: invoiceDetail.waitingTime,
      stopWaitingTime: invoiceDetail.stopWaitingTime,
      trafficTime: invoiceDetail.trafficTime,
      directionPath: invoiceDetail.directionPath,
      isMinFareApplied: invoiceDetail.isMinFareApplied,
      charges: invoiceDetail.charges,
      additionalPrices: mappedAdditionalPrices,
      accessibilityPrices: mappedAccessibilityPrices,
      taxPrices: invoiceDetail.taxPrices,
      isOutsideBoundary: invoiceDetail.isOutsideBoundary,
      priceType: invoiceDetail.priceType,
      total: invoiceDetail.total,
      driverProfit: invoiceDetail.driverProfit,
      bookingFee: invoiceDetail.bookingFee,
      bookingType: invoiceDetail.bookingType,
      distancePrice: invoiceDetail.distancePrice,
      distanceUnit: invoiceDetail.distanceUnit,
      appliedOffer: invoiceDetail.appliedOffer,
      modifierPrice: invoiceDetail.modifierPrice,
      orderReceiveDate: invoiceDetail.orderReceiveDate,
    );
  }

  /// Map price titles from customPrices using chargeId
  List<PriceData>? _mapPriceTitles(
    List<PriceData>? prices,
    List<CustomPrice>? customPrices,
  ) {
    if (prices == null || prices.isEmpty) return prices;
    if (customPrices == null || customPrices.isEmpty) return prices;

    return prices.map((price) {
      // Find matching custom price by chargeId
      final customPrice = customPrices.firstWhere(
        (cp) => cp.id == price.chargeId,
        orElse: () => CustomPrice(id: null, title: null),
      );

      // If found and has title, create new PriceData with mapped title
      if (customPrice.title != null && customPrice.title!.isNotEmpty) {
        return PriceData(
          isActive: price.isActive,
          title: customPrice.title,
          chargeId: price.chargeId,
          type: price.type,
          price: price.price,
          discountedPrice: price.discountedPrice,
          priceType: price.priceType,
          driverProfit: price.driverProfit,
          driverProfitType: price.driverProfitType,
          applyOn: price.applyOn,
          appliedSlots: price.appliedSlots,
          slots: price.slots,
          basePrice: price.basePrice,
          basePriceUnit: price.basePriceUnit,
          unitPrice: price.unitPrice,
          driverProfitPercentage: price.driverProfitPercentage,
          unit: price.unit,
          isApplySlotPrice: price.isApplySlotPrice,
          isSlotInPriceWithUnitCalculation: price.isSlotInPriceWithUnitCalculation,
          isSlotInPriceWithSum: price.isSlotInPriceWithSum,
          isMinFareApplied: price.isMinFareApplied,
          isApplyTax: price.isApplyTax,
          childs: price.childs,
        );
      }

      return price;
    }).toList();
  }

  /// Map accessibility price titles from accessibilities using chargeId
  List<PriceData>? _mapAccessibilityPriceTitles(
    List<PriceData>? prices,
    List<AccessibilityPreference>? accessibilities,
  ) {
    if (prices == null || prices.isEmpty) return prices;
    if (accessibilities == null || accessibilities.isEmpty) return prices;

    return prices.map((price) {
      // Find matching accessibility by chargeId
      final accessibility = accessibilities.firstWhere(
        (a) => a.id == price.chargeId,
        orElse: () => AccessibilityPreference(id: null, accessibility: null),
      );

      // If found and has name, create new PriceData with mapped title
      if (accessibility.accessibility != null && accessibility.accessibility!.isNotEmpty) {
        return PriceData(
          isActive: price.isActive,
          title: accessibility.accessibility,
          chargeId: price.chargeId,
          type: price.type,
          price: price.price,
          discountedPrice: price.discountedPrice,
          priceType: price.priceType,
          driverProfit: price.driverProfit,
          driverProfitType: price.driverProfitType,
          applyOn: price.applyOn,
          appliedSlots: price.appliedSlots,
          slots: price.slots,
          basePrice: price.basePrice,
          basePriceUnit: price.basePriceUnit,
          unitPrice: price.unitPrice,
          driverProfitPercentage: price.driverProfitPercentage,
          unit: price.unit,
          isApplySlotPrice: price.isApplySlotPrice,
          isSlotInPriceWithUnitCalculation: price.isSlotInPriceWithUnitCalculation,
          isSlotInPriceWithSum: price.isSlotInPriceWithSum,
          isMinFareApplied: price.isMinFareApplied,
          isApplyTax: price.isApplyTax,
          childs: price.childs,
        );
      }

      return price;
    }).toList();
  }
}

class _InvoiceItem extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceItem({
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    invoice.title ?? '',
                    fontWeight: FontWeight.w500,
                  ),
                  if (invoice.subTitle?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    AppText.caption(
                      invoice.subTitle!,
                      color: colors.colorText,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppDimens.paddingM),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (invoice.isFree == true)
                  AppText.body(
                    'FREE',
                    color: colors.colorSecondary,
                    fontWeight: FontWeight.w600,
                  )
                else
                  AppText.body(
                    invoice.amount ?? '',
                    fontWeight: FontWeight.w600,
                  ),
                if (invoice.discount?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  AppText.caption(
                    invoice.discount!,
                    color: colors.colorText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ],
              ],
            ),
          ],
        ),

        // Child items
        if (invoice.invoiceChild?.isNotEmpty == true) ...[
          const SizedBox(height: AppDimens.paddingS),
          ...invoice.invoiceChild!.map((child) => Padding(
                padding: const EdgeInsets.only(
                  left: AppDimens.padding,
                  top: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.caption(
                      child.title ?? '',
                      color: colors.colorText,
                    ),
                    AppText.caption(
                      child.amount ?? '',
                      color: colors.colorText,
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

/// Show fare estimation bottom sheet
Future<void> showFareEstimationBottomSheet({
  required BuildContext context,
  required InvoiceDetail? invoiceDetail,
  required String currencySign,
  required int currencyDirection,
  required int decimalPointValue,
  int? distanceUnit,
  String? vehiclePriceId,
  List<CustomPrice>? customPrices,
  List<AccessibilityPreference>? accessibilities,
  List<String>? selectedAccessibilityIds,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.75,
    ),
    builder: (context) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ColoredBox(
        color: context.colors.colorBackground,
        child: FareEstimationBottomSheet(
          invoiceDetail: invoiceDetail,
          currencySign: currencySign,
          currencyDirection: currencyDirection,
          decimalPointValue: decimalPointValue,
          distanceUnit: distanceUnit,
          vehiclePriceId: vehiclePriceId,
          customPrices: customPrices,
          accessibilities: accessibilities,
          selectedAccessibilityIds: selectedAccessibilityIds,
        ),
      ),
    ),
  );
}
