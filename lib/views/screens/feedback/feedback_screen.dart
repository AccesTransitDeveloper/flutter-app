import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/responses/payment/payment_webview_response.dart';
import '../../../viewmodels/feedback_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toolbar.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final bool isFromHistory;

  const FeedbackScreen({
    super.key,
    required this.bookingId,
    this.isFromHistory = true,
  });

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _commentController = TextEditingController();
  final _tipController = TextEditingController();
  late final FeedbackParams _params;

  @override
  void initState() {
    super.initState();
    _params = FeedbackParams(
      bookingId: widget.bookingId,
      isFromHistory: widget.isFromHistory,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(feedbackViewModelProvider(_params));
    final viewModel = ref.read(feedbackViewModelProvider(_params).notifier);

    // Navigate back (matching Kotlin isNavigateBack)
    ref.listen(feedbackViewModelProvider(_params), (previous, next) {
      if (next.isNavigateBack && !(previous?.isNavigateBack ?? false)) {
        context.pop(true);
      }
    });

    // Navigate to home (matching Kotlin isNavigateToHome)
    ref.listen(feedbackViewModelProvider(_params), (previous, next) {
      if (next.isNavigateToHome && !(previous?.isNavigateToHome ?? false)) {
        context.navigateToHome();
      }
    });

    // Handle WebView navigation for card tip payment
    ref.listen(feedbackViewModelProvider(_params), (previous, next) {
      if (next.isNavigateToWebView !=
              (previous?.isNavigateToWebView ?? false) &&
          next.navigateURL != null) {
        viewModel.resetNavigateToWebView();
        context.navigateToWebView(
          webViewData: next.navigateURL,
          onPaymentData: (message) {
            context.goBack();
            final paymentResponse =
                PaymentWebViewResponse.fromJsonString(message);
            final success = paymentResponse?.success ?? false;
            viewModel.handleWebViewPaymentResult(success);
          },
        );
      }
    });

    // Handle navigate to payment screen (matching Kotlin isNavigateToPayment)
    ref.listen(feedbackViewModelProvider(_params), (previous, next) {
      if (next.isNavigateToPayment &&
          !(previous?.isNavigateToPayment ?? false)) {
        viewModel.resetNavigateToPayment();
        _navigateToPaymentSelection(viewModel);
      }
    });

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppToolbar(title: getString(appStr.headingFeedback, 'heading_feedback')),

            // Scrollable content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.booking == null
                      ? Center(
                          child: AppText.body(
                            state.error!,
                            color: colors.colorWarning,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.padding,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: AppDimens.paddingXL),

                              // Driver avatar
                              _buildDriverAvatar(colors, state),

                              const SizedBox(height: AppDimens.paddingM),

                              // Driver name
                              AppText.title(
                                state.driverName.isNotEmpty
                                    ? state.driverName
                                    : getString(appStr.descriptionDriver, 'description_driver'),
                                fontWeight: FontWeight.w600,
                              ),

                              // Favourite button
                              const SizedBox(height: AppDimens.paddingS),
                              GestureDetector(
                                onTap: () => state.isFavourite
                                    ? viewModel.removeFavourite()
                                    : viewModel.addFavourite(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: state.isFavourite
                                        ? const Color(0xFFD04812)
                                        : colors.colorBackgroundGray,
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.paddingS),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.favorite,
                                          size: 14,
                                          color: state.isFavourite
                                              ? colors.colorSelectedText
                                              : colors.colorText),
                                      const SizedBox(width: 4),
                                      AppText.caption(
                                        getString(appStr.buttonFavorite,
                                            'button_favorite'),
                                        color: state.isFavourite
                                            ? colors.colorSelectedText
                                            : colors.colorText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Distance & time
                              if (state.distanceStr != null ||
                                  state.timeStr != null) ...[
                                const SizedBox(height: AppDimens.paddingXS),
                                AppText.body(
                                  [state.distanceStr, state.timeStr]
                                      .whereType<String>()
                                      .join(' · '),
                                  color: colors.colorTextHint,
                                ),
                              ],

                              const SizedBox(height: AppDimens.paddingXL),

                              // Rating subtitle
                              AppText.body(
                                getString(appStr.subHeadingRateYourRideExperience, 'sub_heading_rate_your_ride_experience'),
                                fontWeight: FontWeight.w500,
                              ),

                              const SizedBox(height: AppDimens.paddingM),

                              // Star rating row
                              _buildStarRating(colors, state, viewModel),

                              const SizedBox(height: AppDimens.paddingS),

                              // Rating label
                              AppText.caption(
                                _getRatingLabel(state.selectedRating),
                                color: colors.colorTextHint,
                              ),

                              const SizedBox(height: AppDimens.paddingXL),

                              // Tip section (matching Kotlin isShowTipOptions)
                              if (state.isShowTipOptions)
                                _buildTipSection(colors, state, viewModel),

                              // Comment section
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AppText.body(
                                  getString(appStr.subHeadingComment, 'sub_heading_comment'),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: AppDimens.paddingS),

                              AppTextField(
                                controller: _commentController,
                                hintText: getString(appStr.hintWriteYourRideExperience, 'hint_write_your_ride_experience'),
                                maxLines: 4,
                                onChanged: viewModel.updateComment,
                              ),

                              const SizedBox(height: AppDimens.paddingXL),
                            ],
                          ),
                        ),
            ),

            // Bottom action buttons
            if (!state.isLoading && state.booking != null)
              _buildBottomButtons(colors, state, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAvatar(AppColorPalette colors, FeedbackState state) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: colors.colorBackgroundGray,
        shape: BoxShape.circle,
      ),
      child: state.driverImageUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: state.driverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(
                  Icons.person,
                  color: colors.colorTextHint,
                  size: 40,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  color: colors.colorTextHint,
                  size: 40,
                ),
              ),
            )
          : Icon(
              Icons.person,
              color: colors.colorTextHint,
              size: 40,
            ),
    );
  }

  Widget _buildStarRating(
    AppColorPalette colors,
    FeedbackState state,
    FeedbackViewModel viewModel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = starNumber <= state.selectedRating;

        return GestureDetector(
          onTap: () => viewModel.selectRating(starNumber),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingS,
            ),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_border_rounded,
              size: 44,
              color: isSelected ? colors.colorPrimary : colors.colorTextHint,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTipSection(
    AppColorPalette colors,
    FeedbackState state,
    FeedbackViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(
          getString(appStr.subHeadingTipYourDriver, 'sub_heading_tip_your_driver'),
          fontWeight: FontWeight.w500,
        ),

        const SizedBox(height: AppDimens.paddingM),

        // Tip options row
        if (state.tipOptions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: state.tipOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final tip = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimens.paddingS),
                  child: _buildTipChip(colors, tip, () {
                    viewModel.selectTip(index);
                    _tipController.clear();
                  }),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: AppDimens.paddingM),

        // Custom tip input
        AppTextField(
          controller: _tipController,
          hintText: getString(appStr.hintEnterTipAmount, 'hint_enter_tip_amount'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            viewModel.updateTipAmount(value);
          },
        ),

        // Tip payment failed message
        if (state.isTipPaymentFailed) ...[
          const SizedBox(height: AppDimens.paddingM),
          AppText.caption(
            getString(appStr.errorTipPaymentFailed, 'error_tip_payment_failed'),
            color: colors.colorWarning,
          ),
        ],

        // Payment method selector (matching Kotlin: shown when showPaymentOption && isTipPaymentFailed)
        if (state.showPaymentOption && state.isTipPaymentFailed) ...[
          const SizedBox(height: AppDimens.padding),
          GestureDetector(
            onTap: () => _navigateToPaymentSelection(viewModel),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.paddingS,
                horizontal: AppDimens.paddingM,
              ),
              decoration: BoxDecoration(
                color: colors.colorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.body(
                    state.paymentMethodName.isNotEmpty
                        ? state.paymentMethodName
                        : getString(appStr.descriptionSelectPaymentGateway, 'description_select_payment_gateway'),
                    color: colors.colorTextHint,
                  ),
                  Icon(
                    Icons.credit_card,
                    size: 24,
                    color: colors.colorPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: AppDimens.paddingXL),
      ],
    );
  }

  Widget _buildTipChip(
    AppColorPalette colors,
    TipOption tip,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.paddingS),
          border: Border.all(
            color: tip.isSelected
                ? colors.colorText
                : colors.colorText.withValues(alpha: 0.2),
          ),
        ),
        child: AppText.caption(
          tip.priceStr,
          color: tip.isSelected
              ? colors.colorText
              : colors.colorText.withValues(alpha: 0.8),
          fontWeight: tip.isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBottomButtons(
    AppColorPalette colors,
    FeedbackState state,
    FeedbackViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFilledButton(
            text: getString(appStr.buttonSubmit, 'button_submit'),
            isLoading: state.isLoading,
            onPressed: viewModel.submitRating,
          ),
          const SizedBox(height: AppDimens.paddingS),
          AppOutlinedButton(
            text: getString(appStr.buttonMaybeLater, 'button_maybe_later'),
            onPressed: state.isLoading
                ? null
                : () => viewModel.skipRating(),
          ),
        ],
      ),
    );
  }

  /// Navigate to payment selection screen (matching Kotlin onNavigateToPayment)
  Future<void> _navigateToPaymentSelection(FeedbackViewModel viewModel) async {
    final card = await context.navigateToPayment(
      myBookingPaymentSetting: viewModel.paymentSetting,
      isFromFeedBack: true,
    );
    if (card != null && mounted) {
      final gatewayType = PaymentGatewayType.fromValue(card.paymentGatewayType);
      viewModel.updatePaymentMethod(
        card.paymentGatewayType ?? 0,
        gatewayType?.getName() ?? '',
      );
    }
  }

  String _getRatingLabel(int rating) {
    return switch (rating) {
      1 => getString(appStr.descriptionRateAwful, 'description_rate_awful'),
      2 => getString(appStr.descriptionRateSad, 'description_rate_sad'),
      3 => getString(appStr.descriptionRateGood, 'description_rate_good'),
      4 => getString(appStr.descriptionRateVeryGood, 'description_rate_very_good'),
      5 => getString(appStr.descriptionRateExcellent, 'description_rate_excellent'),
      _ => '',
    };
  }
}
