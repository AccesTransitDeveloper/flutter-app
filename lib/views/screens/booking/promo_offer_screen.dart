import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/booking/promo_code_response.dart';
import '../../../viewmodels/promo_offer_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_toolbar.dart';

class PromoOfferScreen extends ConsumerStatefulWidget {
  final PromoOfferParams params;

  const PromoOfferScreen({
    super.key,
    required this.params,
  });

  @override
  ConsumerState<PromoOfferScreen> createState() => _PromoOfferScreenState();
}

class _PromoOfferScreenState extends ConsumerState<PromoOfferScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(promoOfferViewModelProvider(widget.params));

    // Listen for navigation back
    ref.listen<PromoOfferState>(
      promoOfferViewModelProvider(widget.params),
      (previous, next) {
        if (next.isNavigateBack && !previous!.isNavigateBack) {
          context.pop(next.selectedPromo);
        }
        if (next.snackBarMessage != null && next.snackBarMessage!.isNotEmpty) {
          context.showSnackBar(next.snackBarMessage!);
          ref
              .read(promoOfferViewModelProvider(widget.params).notifier)
              .clearSnackBar();
        }
      },
    );

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppToolbar(title: getString(appStr.headingPromoOffers, 'heading_promo_offers')),
            Expanded(
              child: state.isDataLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? _buildErrorState(context, ref, state.error!)
                      : state.promoCodesList.isEmpty
                          ? _buildEmptyState(colors)
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(promoOfferViewModelProvider(widget.params)
                                      .notifier)
                                  .refresh(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(AppDimens.padding),
                                itemCount: state.promoCodesList.length,
                                itemBuilder: (context, index) {
                                  return _PromoCodeCard(
                                    promoCode: state.promoCodesList[index],
                                    colors: colors,
                                    isLoading: state.isLoading,
                                    onApply: () {
                                      ref
                                          .read(promoOfferViewModelProvider(
                                                  widget.params)
                                              .notifier)
                                          .applyPromoCode(
                                              state.promoCodesList[index]);
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.colorText,
              size: 48,
            ),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              getString(appStr.errorUnableToLoadPromoCodes, 'error_unable_to_load_promo_codes'),
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: AppDimens.paddingS),
            AppText.caption(
              error,
              color: colors.colorText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.padding),
            AppFilledButton(
              text: getString(appStr.buttonRetry, 'button_retry'),
              width: 120,
              onPressed: () => ref
                  .read(promoOfferViewModelProvider(widget.params).notifier)
                  .refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorPalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: colors.colorText,
              size: 48,
            ),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              getString(appStr.errorNoPromoOffers, 'error_no_promo_offers'),
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCodeCard extends StatelessWidget {
  final PromoCodes promoCode;
  final AppColorPalette colors;
  final bool isLoading;
  final VoidCallback onApply;

  const _PromoCodeCard({
    required this.promoCode,
    required this.colors,
    required this.isLoading,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = promoCode.bannerImageUrl != null
        ? ServerConfig.getFullImageUrl(promoCode.bannerImageUrl!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.padding),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        border: Border.all(
          color: colors.colorText.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.buttonRadius),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: colors.colorPrimary.withValues(alpha: 0.1),
                  child: Center(
                    child: Icon(
                      Icons.local_offer,
                      color: colors.colorPrimary,
                      size: 32,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: colors.colorPrimary.withValues(alpha: 0.1),
                  child: Center(
                    child: Icon(
                      Icons.local_offer,
                      color: colors.colorPrimary,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppDimens.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                if (promoCode.title != null)
                  AppText.body(
                    promoCode.title!,
                    fontWeight: FontWeight.w600,
                  ),

                const SizedBox(height: AppDimens.paddingS),

                // Promo code
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: colors.colorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.paddingS),
                    border: Border.all(
                      color: colors.colorPrimary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: AppText.caption(
                    promoCode.code ?? '',
                    color: colors.colorPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppDimens.paddingM),

                // Description
                if (promoCode.description != null)
                  AppText.caption(
                    promoCode.description!,
                    color: colors.colorText.withValues(alpha: 0.7),
                  ),

                const SizedBox(height: AppDimens.padding),

                // Apply button
                AppFilledButton(
                  text: getString(appStr.buttonApply, 'button_apply'),
                  isLoading: isLoading,
                  onPressed: onApply,
                ),

                // Terms and conditions
                if (promoCode.termsAndConditions != null &&
                    promoCode.termsAndConditions!.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.padding),
                  ExpansionTile(
                    title: AppText.caption(
                      getString(appStr.descriptionTermsConditions, 'description_terms_conditions'),
                      fontWeight: FontWeight.w500,
                    ),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: AppDimens.paddingS),
                    children: promoCode.termsAndConditions!
                        .map(
                          (term) => Padding(
                            padding: const EdgeInsets.only(bottom: AppDimens.paddingXS),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.caption(
                                  '• ',
                                  color: colors.colorText.withValues(alpha: 0.7),
                                ),
                                Expanded(
                                  child: AppText.caption(
                                    term,
                                    color: colors.colorText.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
