import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/api/server_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/account_viewmodel.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/move_server_bottom_sheet.dart';
import '../../../views/widgets/multi_tap_detector.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _navigateToProfile(BuildContext context, WidgetRef ref) async {
    await context.navigateToProfile();
    // Refresh user data when returning from profile screen
    ref.read(accountViewModelProvider.notifier).refreshUserData();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(accountViewModelProvider);
    final entity = state.entity;

    if (entity == null) {
      return AppScaffold(
        body: SafeArea(child: _buildShimmer(context)),
      );
    }

    // Get rating with 1 decimal place
    final rating = entity.rate?.toStringAsFixed(1) ?? '5.0';

    // Get full image URL
    final imageUrl = entity.imageUrl != null && entity.imageUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(entity.imageUrl)
        : null;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Fixed Profile Header - Name on left, image on right
          Padding(
            padding: const EdgeInsets.all(AppDimens.padding),
            child: InkWell(
              onTap: () => _navigateToProfile(context, ref),
              borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
              child: Row(
                children: [
                  // Name and Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.heading(
                          state.userName ?? '',
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: AppDimens.paddingS),
                        // Rating with gray background
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingS,
                            vertical: AppDimens.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: colors.colorBackgroundGray,
                            borderRadius: BorderRadius.circular(AppDimens.paddingXS),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: AppDimens.iconSizeSmall,
                                color: colors.colorText,
                              ),
                              const SizedBox(width: AppDimens.paddingXS),
                              AppText.caption(rating),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile Image on right
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 32,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) => CircleAvatar(
                        radius: 32,
                        backgroundColor: colors.colorBackgroundGray,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: colors.colorText,
                        ),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 32,
                        backgroundColor: colors.colorBackgroundGray,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: colors.colorText,
                        ),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colors.colorBackgroundGray,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: colors.colorText,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons - First Row (Help, Wallet)
                  Row(
                    children: [
                      Expanded(
                        child: _AccountActionButton(
                          icon: Icons.help_outline,
                          label: getString(appStr.headingHelp, 'heading_help'),
                          onTap: () => context.navigateToContactUs(),
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: _AccountActionButton(
                          icon: Icons.account_balance_wallet_outlined,
                          label: getString(appStr.headingWallet, 'heading_wallet'),
                          onTap: () => context.navigateToPayment(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingM),

                  // Action Buttons - Second Row (Legal, Inbox)
                  Row(
                    children: [
                      Expanded(
                        child: _AccountActionButton(
                          icon: Icons.gavel_outlined,
                          label: getString(appStr.headingLegal, 'heading_legal'),
                          onTap: () => context.navigateToLegal(),
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: _AccountActionButton(
                          icon: Icons.mail_outline,
                          label: getString(appStr.headingInbox, 'heading_inbox'),
                          onTap: () => context.navigateToInbox(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingXL),

                  // Menu Items
                  _AccountMenuItem(
                    icon: Icons.history,
                    title: getString(appStr.headingActivity, 'heading_activity'),
                    onTap: () => context.navigateToActivity(),
                  ),
                  _AccountMenuItem(
                    icon: Icons.description_outlined,
                    title: getString(appStr.headingDocument, 'heading_document'),
                    onTap: () => context.navigateToDocuments(),
                  ),
                  _AccountMenuItem(
                    icon: Icons.card_giftcard_outlined,
                    title: getString(appStr.headingRedeem, 'heading_redeem'),
                    onTap: () => context.navigateToRedeem(),
                  ),
                  _AccountMenuItem(
                    icon: Icons.share_outlined,
                    title: getString(appStr.headingReferral, 'heading_referral'),
                    onTap: () => context.navigateToReferral(),
                  ),
                  _AccountMenuItem(
                    icon: Icons.favorite_outline,
                    title: getString(appStr.headingFavourites, 'heading_favourites'),
                    onTap: () => context.navigateToFavouriteDrivers(),
                  ),
                  _AccountMenuItem(
                    icon: Icons.settings_outlined,
                    title: getString(appStr.headingSetting, 'heading_setting'),
                    onTap: () => context.navigateToSettings(),
                  ),
                  const SizedBox(height: AppDimens.paddingXL),

                  // App Version (tap to open server switcher)
                  _AppVersionWidget(
                    onTap: () => showMoveServerBottomSheet(context, ref),
                  ),
                  const SizedBox(height: AppDimens.padding),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget shimmerBox({double? width, required double height, double radius = AppDimens.paddingXS}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerBox(width: 160, height: 28),
                      const SizedBox(height: AppDimens.paddingS),
                      shimmerBox(width: 60, height: 24, radius: AppDimens.paddingXS),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.paddingXL),

            // Action buttons row 1
            Row(
              children: [
                Expanded(child: shimmerBox(height: 52, radius: AppDimens.paddingM)),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(child: shimmerBox(height: 52, radius: AppDimens.paddingM)),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Action buttons row 2
            Row(
              children: [
                Expanded(child: shimmerBox(height: 52, radius: AppDimens.paddingM)),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(child: shimmerBox(height: 52, radius: AppDimens.paddingM)),
              ],
            ),

            const SizedBox(height: AppDimens.paddingXL),

            // Menu items
            for (int i = 0; i < 6; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimens.padding),
                    shimmerBox(width: 120, height: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Account Action Button (Help, Wallet, Safety, Inbox)
class _AccountActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.paddingM),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.paddingM),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: colors.colorText,
              size: AppDimens.iconSize,
            ),
            const SizedBox(width: AppDimens.paddingM),
            AppText.body(
              label,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}

// Account Menu Item (Settings, Send a gift, etc.)
class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
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
            Icon(
              icon,
              color: colors.colorText,
              size: AppDimens.iconSize,
            ),
            const SizedBox(width: AppDimens.padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    title,
                    fontWeight: FontWeight.w500,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      subtitle!,
                      color: colors.colorText,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// App Version Widget
class _AppVersionWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const _AppVersionWidget({this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        final versionText = version.isNotEmpty
            ? version
            : '';

        return MultiTapDetector(
          onMultiTap: onTap ?? () {},
          child: Center(
            child: AppText.caption(
              versionText,
              color: colors.colorText,
            ),
          ),
        );
      },
    );
  }
}
