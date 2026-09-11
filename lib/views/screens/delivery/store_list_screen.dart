import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/delivery/delivery_responses.dart';
import '../../../viewmodels/store_list_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';
import 'dynamic_group_view.dart';

/// Store list for a delivery category — mirrors the native dynamic-group /
/// merchant list: category title, search, and the restaurant list.
class StoreListScreen extends ConsumerStatefulWidget {
  final StoreListParams params;

  const StoreListScreen({super.key, required this.params});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = storeListViewModelProvider(widget.params);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nav bar: back + category title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
                vertical: AppDimens.paddingS,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.colorText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: AppText.title(
                      widget.params.categoryName,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: colors.colorBackgroundGray,
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: colors.colorTextHint),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style:
                            TextStyle(fontSize: 14, color: colors.colorText),
                        decoration: InputDecoration(
                          hintText: 'Search stores',
                          hintStyle: TextStyle(
                              fontSize: 14, color: colors.colorTextHint),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: notifier.onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingS),

            Expanded(child: _buildBody(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, StoreListState state, StoreListViewModel notifier) {
    final colors = context.colors;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final merchants = state.visibleMerchants;
    if (merchants.isEmpty && !state.showGroups) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingXL),
          child: AppText.body(
            state.errorMessage ?? 'No stores found near you.',
            color: colors.colorTextHint,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Compose the scrolling content: curated group rails, then the all-stores
    // list under a section header (native dynamic-group layout).
    final items = <Widget>[];
    if (state.showGroups) {
      for (final group in state.groups) {
        items.add(DynamicGroupSection(group: group));
      }
      if (merchants.isNotEmpty) {
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(AppDimens.padding,
              AppDimens.paddingS, AppDimens.padding, AppDimens.paddingS),
          child: AppText.title('All stores', fontWeight: FontWeight.w700),
        ));
      }
    }
    for (final merchant in merchants) {
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.padding, 0, AppDimens.padding, AppDimens.padding),
        child: _MerchantCard(merchant: merchant),
      ));
    }

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView(
        padding: const EdgeInsets.only(top: AppDimens.paddingS),
        children: items,
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final Merchant merchant;

  const _MerchantCard({required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOpen = merchant.isOpen ?? true;
    final imageUrl = ServerConfig.getFullImageUrl(merchant.imageUrl);

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.buttonRadius),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(height: 140, color: colors.colorBackgroundGray),
                  errorWidget: (_, _, _) => Container(
                    height: 140,
                    color: colors.colorBackgroundGray,
                    child: Icon(Icons.storefront,
                        color: colors.colorTextHint, size: 40),
                  ),
                ),
                if (!isOpen)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: AppText.body(
                        'Closed',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText.title(
                        merchant.name ?? '',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (merchant.customerRate != null) ...[
                      const SizedBox(width: AppDimens.paddingS),
                      Icon(Icons.star, size: 16, color: colors.colorPrimary),
                      const SizedBox(width: 2),
                      AppText.caption(
                        merchant.customerRate!.toStringAsFixed(1),
                        fontWeight: FontWeight.w600,
                        color: colors.colorText,
                      ),
                    ],
                  ],
                ),
                if ((merchant.address ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppDimens.paddingXS),
                  AppText.caption(
                    merchant.address!,
                    color: colors.colorTextHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppDimens.paddingXS),
                Row(
                  children: [
                    if (merchant.distance != null) ...[
                      Icon(Icons.location_on_outlined,
                          size: 14, color: colors.colorTextHint),
                      const SizedBox(width: 2),
                      AppText.caption(_formatDistance(merchant.distance!),
                          color: colors.colorTextHint),
                      const SizedBox(width: AppDimens.paddingM),
                    ],
                    if (merchant.maxPreparationTime != null) ...[
                      Icon(Icons.access_time,
                          size: 14, color: colors.colorTextHint),
                      const SizedBox(width: 2),
                      AppText.caption('${merchant.maxPreparationTime!.toInt()} min',
                          color: colors.colorTextHint),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toInt()} m';
  }
}
