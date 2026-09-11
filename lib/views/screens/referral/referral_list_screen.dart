import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/referral/referral_history_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/referral_viewmodel.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';

class ReferralListScreen extends ConsumerWidget {
  const ReferralListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(referralListViewModelProvider);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.descriptionReferralList, 'description_referral_list'),
            ),

            // Content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.referrals.isEmpty
                      ? Center(
                          child: AppText.body(
                            getString(appStr.descriptionNoDataFound, 'description_no_data_found'),
                            color: colors.colorText,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(referralListViewModelProvider.notifier)
                              .refresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.padding,
                              vertical: AppDimens.paddingM,
                            ),
                            itemCount: state.referrals.length,
                            separatorBuilder: (context, index) => Divider(
                              color: colors.colorText.withValues(alpha: 0.2),
                            ),
                            itemBuilder: (context, index) {
                              final referral = state.referrals[index];
                              return _ReferralItem(referral: referral);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralItem extends StatelessWidget {
  final ReferralUser referral;

  const _ReferralItem({required this.referral});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final imageUrl = referral.imageUrl != null && referral.imageUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(referral.imageUrl)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
      child: Row(
        children: [
          // Profile image
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => _PlaceholderImage(colors: colors),
              errorWidget: (context, url, error) =>
                  _PlaceholderImage(colors: colors),
            )
          else
            _PlaceholderImage(colors: colors),

          const SizedBox(width: AppDimens.padding),

          // Name and phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(
                  referral.fullName.isNotEmpty ? referral.fullName : '',
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: AppDimens.paddingXS),
                AppText.caption(
                  referral.formattedPhone,
                  color: colors.colorText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final AppColorPalette colors;

  const _PlaceholderImage({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.colorBackgroundGray,
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
      ),
      child: Icon(
        Icons.image,
        color: colors.colorText,
        size: 24,
      ),
    );
  }
}
