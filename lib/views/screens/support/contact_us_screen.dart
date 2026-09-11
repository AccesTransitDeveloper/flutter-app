import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/localization/string_constants.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/support_ticket_utils.dart';
import '../../../data/api/server_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/contact_us_viewmodel.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';
import '../../../views/item/sticky_date_header.dart';
import '../../bottomsheets/new_ticket_bottomsheet.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(contactUsViewModelProvider);
    final viewModel = ref.read(contactUsViewModelProvider.notifier);

    // Listen for errors
    ref.listen<ContactUsState>(contactUsViewModelProvider, (previous, next) {
      if (next.error != null && previous?.error == null) {
        context.showErrorSnackBar(next.error!);
        viewModel.clearError();
      }
      if (next.showSupportTicketBottomSheet &&
          !(previous?.showSupportTicketBottomSheet ?? false)) {
        _showNewTicketBottomSheet(context, viewModel);
      }
    });

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingContactUs, 'heading_contact_us'),
            ),

            // Sticky header (not scrollable)
            _buildContactHeader(colors, state, viewModel),

            // Content (scrollable)
            Expanded(
              child: state.isDataLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: viewModel.refresh,
                      child: state.supportTicketMap.isEmpty
                          ? ListView(
                              children: [_buildEmptyState(colors)],
                            )
                          : _TicketsList(
                              supportTicketMap: state.supportTicketMap,
                              onRefresh: viewModel.refresh,
                            ),
                    ),
            ),

            // Bottom button - small centered with icon
            _buildBottomButton(colors, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHeader(
    AppColorPalette colors,
    ContactUsState state,
    ContactUsViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.padding),
      child: Column(
        children: [
          // Image and title
          Row(
            children: [
              // Contact us image
              SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  'assets/images/contact_us.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.support_agent_outlined,
                      size: 80,
                      color: colors.colorText,
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDimens.padding),
              // Title and buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.title(
                      getString(appStr.descriptionThankYouForChoosing, 'description_thank_you_for_choosing').replacePlaceholders({
                        StringConstant.appName: getString(appStr.appName, 'app_name'),
                      }),
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: AppDimens.padding),
                    // Email and Call buttons
                    Row(
                      children: [
                        _buildContactButton(
                          colors: colors,
                          icon: Icons.email_outlined,
                          label: getString(appStr.buttonEmail, 'button_email'),
                          onTap: viewModel.sendEmail,
                        ),
                        const SizedBox(width: AppDimens.paddingM),
                        _buildContactButton(
                          colors: colors,
                          icon: Icons.phone_outlined,
                          label: getString(appStr.buttonCall, 'button_call'),
                          onTap: viewModel.makeCall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required AppColorPalette colors,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: AppText.body(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.colorText,
        side: BorderSide(color: colors.colorText.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorPalette colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 80,
            color: colors.colorText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimens.padding),
          AppText.body(
            getString(appStr.descriptionNoTicketsFound, 'description_no_tickets_found'),
            color: colors.colorText,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(AppColorPalette colors, ContactUsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.padding,
        vertical: AppDimens.paddingS,
      ),
      child: Center(
        child: Material(
          color: colors.colorButtonBackground,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          child: InkWell(
            onTap: viewModel.showNewTicketSheet,
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingL,
                vertical: AppDimens.paddingS,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline,
                    color: colors.colorButtonText,
                    size: AppDimens.iconSize,
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  AppText.body(
                    getString(appStr.buttonRaiseNewTicket, 'button_raise_new_ticket'),
                    color: colors.colorButtonText,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNewTicketBottomSheet(BuildContext context, ContactUsViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NewTicketBottomSheet(
        onTicketCreated: () {
          viewModel.hideNewTicketSheet();
          viewModel.refresh();
        },
      ),
    ).whenComplete(() {
      viewModel.hideNewTicketSheet();
    });
  }

}

/// Tickets list with sticky date headers
class _TicketsList extends StatelessWidget {
  final Map<String, List<SupportTicketItem>> supportTicketMap;
  final Future<void> Function()? onRefresh;

  const _TicketsList({
    required this.supportTicketMap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = supportTicketMap.entries.toList();

    return CustomScrollView(
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
              // Tickets for this date
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _TicketItem(
                      ticket: entry.value[index],
                      onRefresh: onRefresh,
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ],
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppDimens.paddingXL),
        ),
      ],
    );
  }
}

/// Single ticket item
class _TicketItem extends StatelessWidget {
  final SupportTicketItem ticket;
  final Future<void> Function()? onRefresh;

  const _TicketItem({required this.ticket, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = SupportTicketUtils.getStatusColor(ticket.status ?? '');
    final statusText = SupportTicketUtils.getStatusText(ticket.status ?? '');
    final hasImage = ticket.supportTicket?.imageUrl != null &&
        ticket.supportTicket!.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () async {
        final result = await context.navigateToTicketDetail(ticket);
        if (result == true) {
          onRefresh?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.colorText.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Ticket info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket ID label
                  AppText.caption(
                    ticket.ticketTitle.toUpperCase(),
                    color: colors.colorText,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  // Subject (green)
                  AppText.body(
                    ticket.supportTicket?.subject ?? '',
                    color: colors.colorPrimary,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  // Description
                  AppText.caption(
                    ticket.supportTicket?.description ?? '',
                    color: colors.colorText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  // Date/Time
                  AppText.caption(
                    ticket.dateTimeStr,
                    color: colors.colorText,
                    fontSize: 11,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppDimens.paddingS),

            // Right side - Status badge and optional image
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: AppDimens.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadiusSmall),
                  ),
                  child: AppText.caption(
                    statusText.toUpperCase(),
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                // Image (if available)
                if (hasImage) ...[
                  const SizedBox(height: AppDimens.paddingS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadiusSmall),
                    child: Image.network(
                      ServerConfig.getFullImageUrl(ticket.supportTicket!.imageUrl),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          color: colors.colorBackgroundGray,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: colors.colorBackgroundGray,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colors.colorText,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

