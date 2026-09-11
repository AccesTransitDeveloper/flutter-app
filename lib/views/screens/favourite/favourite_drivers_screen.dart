import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/driver/favourite_driver_response.dart';
import '../../../viewmodels/favourite_drivers_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_toolbar.dart';

class FavouriteDriversScreen extends ConsumerWidget {
  const FavouriteDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(favouriteDriversViewModelProvider);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppToolbar(
              title: getString(
                  appStr.headingFavourites, 'heading_favourites'),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.drivers.isEmpty
                      ? Center(
                          child: AppText.body(
                            getString(appStr.descriptionNoDataFound,
                                'description_no_data_found'),
                            color: colors.colorText.withValues(alpha: 0.5),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(
                                  favouriteDriversViewModelProvider.notifier)
                              .refresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.padding,
                              vertical: AppDimens.paddingM,
                            ),
                            itemCount: state.drivers.length,
                            separatorBuilder: (context, index) => Divider(
                              color:
                                  colors.colorText.withValues(alpha: 0.2),
                            ),
                            itemBuilder: (context, index) {
                              final driver = state.drivers[index];
                              return _FavouriteDriverItem(
                                driver: driver,
                                onRemove: () => _showRemoveDialog(
                                    context, ref, driver),
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

  void _showRemoveDialog(
      BuildContext context, WidgetRef ref, FavouriteDriver driver) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.colorBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.padding),
        ),
        content: AppText.body(
          getString(appStr.descriptionDeleteFavourite,
              'description_delete_favourite'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: AppText.body(
              getString(appStr.buttonCancel, 'button_cancel'),
              color: colors.colorTextHint,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (driver.id != null) {
                ref
                    .read(favouriteDriversViewModelProvider.notifier)
                    .deleteFavouriteDriver(driver.id!);
              }
            },
            child: AppText.body(
              getString(appStr.buttonYes, 'button_yes'),
              color: colors.colorPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavouriteDriverItem extends StatelessWidget {
  final FavouriteDriver driver;
  final VoidCallback onRemove;

  const _FavouriteDriverItem({
    required this.driver,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final imageUrl = driver.imageUrl != null && driver.imageUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(driver.imageUrl)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
      child: Row(
        children: [
          // Driver image
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) =>
                  _PlaceholderImage(colors: colors),
              errorWidget: (context, url, error) =>
                  _PlaceholderImage(colors: colors),
            )
          else
            _PlaceholderImage(colors: colors),

          const SizedBox(width: AppDimens.paddingM),

          // Driver name
          Expanded(
            child: AppText.body(
              driver.fullName ?? '',
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: AppDimens.paddingM),

          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS,
              ),
              decoration: BoxDecoration(
                color: colors.colorSecondary,
                borderRadius: BorderRadius.circular(AppDimens.paddingS),
              ),
              child: AppText.caption(
                getString(appStr.buttonRemove, 'button_remove')
                    .toLowerCase(),
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
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
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: colors.colorBackgroundGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.person,
        color: colors.colorText.withValues(alpha: 0.4),
        size: 32,
      ),
    );
  }
}
