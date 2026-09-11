import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/cancellation_policy_viewmodel.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';

class CancellationPolicyScreen extends ConsumerWidget {
  final String vehiclePriceId;

  const CancellationPolicyScreen({
    super.key,
    required this.vehiclePriceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(cancellationPolicyViewModelProvider(vehiclePriceId));

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(title: getString(appStr.headingCancellationPolicy, 'heading_cancellation_policy')),

            // Content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? _buildErrorState(context, ref, state.error!)
                      : state.policyItems.isEmpty
                          ? _buildEmptyState(colors)
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(cancellationPolicyViewModelProvider(
                                          vehiclePriceId)
                                      .notifier)
                                  .refresh(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(AppDimens.padding),
                                itemCount: state.policyItems.length,
                                itemBuilder: (context, index) {
                                  return _PolicyItem(
                                    index: index + 1,
                                    text: state.policyItems[index],
                                    colors: colors,
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
              getString(appStr.errorUnableToLoadCancellationPolicy, 'error_unable_to_load_cancellation_policy'),
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
                  .read(cancellationPolicyViewModelProvider(vehiclePriceId)
                      .notifier)
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
              Icons.description_outlined,
              color: colors.colorText,
              size: 48,
            ),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              getString(appStr.errorNoCancellationPolicy, 'error_no_cancellation_policy'),
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final int index;
  final String text;
  final AppColorPalette colors;

  const _PolicyItem({
    required this.index,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point with number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.colorPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppText.caption(
                '$index',
                color: colors.colorPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
          // Policy text
          Expanded(
            child: AppText.body(
              text,
              color: colors.colorText,
            ),
          ),
        ],
      ),
    );
  }
}
