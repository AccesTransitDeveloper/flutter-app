import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/notification/notification_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/inbox_viewmodel.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';
import '../../../views/item/sticky_date_header.dart';

class InboxScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const InboxScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(inboxViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(inboxViewModelProvider);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingInbox, 'heading_inbox'),
              showBackButton: widget.showBackButton,
            ),

            // Content
            Expanded(
              child: state.isLoading
                  ? _buildShimmer(context)
                  : state.notifications.isEmpty
                      ? Center(
                          child: AppText.body(
                            getString(appStr.descriptionNoDataFound,
                                'description_no_data_found'),
                            color: colors.colorText,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh:
                              ref.read(inboxViewModelProvider.notifier).refresh,
                          child: _NotificationsList(
                            scrollController: _scrollController,
                            groupedNotifications: state.groupedNotifications,
                            isLoadingMore: state.isLoadingMore,
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
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerBox(width: 140, height: 14),
                      const SizedBox(height: AppDimens.paddingS),
                      shimmerBox(height: 12),
                      const SizedBox(height: AppDimens.paddingXS),
                      shimmerBox(width: 60, height: 10),
                    ],
                  ),
                ),
                if (index % 2 == 0) ...[
                  const SizedBox(width: AppDimens.padding),
                  shimmerBox(width: 75, height: 75, radius: AppDimens.buttonRadiusSmall),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final ScrollController scrollController;
  final Map<String, List<NotificationItem>> groupedNotifications;
  final bool isLoadingMore;

  const _NotificationsList({
    required this.scrollController,
    required this.groupedNotifications,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = groupedNotifications.entries.toList();

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Create a SliverMainAxisGroup for each date
        for (final entry in entries)
          SliverMainAxisGroup(
            slivers: [
              // Sticky header
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyDateHeaderDelegate(
                  date: entry.key,
                  colors: colors,
                ),
              ),
              // Notifications for this date
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final showDivider = index < entry.value.length - 1;
                    return _NotificationItemWidget(
                      item: entry.value[index],
                      showDivider: showDivider,
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ],
          ),

        // Loading more indicator
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.padding),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppDimens.paddingXL),
        ),
      ],
    );
  }
}

class _NotificationItemWidget extends StatelessWidget {
  final NotificationItem item;
  final bool showDivider;

  const _NotificationItemWidget({
    required this.item,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final imageUrl = item.imageUrl != null && item.imageUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(item.imageUrl)
        : null;

    final notificationTime = AppDateUtils.formatString(
      item.createdAt,
      DateFormat.hourMinuteFormat,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.padding,
        vertical: AppDimens.padding,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.colorText.withValues(alpha: 0.2),
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                AppText.body(
                  item.title ?? '',
                  fontWeight: FontWeight.w600,
                ),

                const SizedBox(height: AppDimens.paddingXS),

                // Message
                AppText.body(
                  item.message ?? '',
                  color: colors.colorText,
                ),

                const SizedBox(height: AppDimens.paddingXS),

                // Time
                AppText.caption(
                  notificationTime,
                  color: colors.colorText,
                ),
              ],
            ),
          ),

          // Image (if available)
          if (imageUrl != null) ...[
            const SizedBox(width: AppDimens.padding),
            CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppDimens.buttonRadiusSmall),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => _PlaceholderImage(colors: colors),
              errorWidget: (context, url, error) =>
                  _PlaceholderImage(colors: colors),
            ),
          ],
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
        borderRadius: BorderRadius.circular(AppDimens.buttonRadiusSmall),
      ),
      child: Icon(
        Icons.image,
        color: colors.colorText,
        size: 24,
      ),
    );
  }
}
