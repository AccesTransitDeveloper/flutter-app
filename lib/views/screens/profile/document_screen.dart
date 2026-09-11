import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/document_utils.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/document/document_response.dart';
import '../../../models/webview_data_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/document_viewmodel.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';
import '../../bottomsheets/document_edit_bottom_sheet.dart';

class DocumentScreen extends ConsumerWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(documentViewModelProvider);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppToolbar(
              title: getString(appStr.headingDocument, 'heading_document'),
            ),
            Expanded(
              child: _buildBody(context, ref, state, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DocumentState state,
    dynamic colors,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colors.colorText,
            ),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              state.error!,
              color: colors.colorText,
            ),
          ],
        ),
      );
    }

    final documents = state.documents;
    if (documents == null || documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: colors.colorText,
            ),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              getString(appStr.errorNoDocumentFound, 'error_no_document_found'),
              color: colors.colorText,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(documentViewModelProvider.notifier).refresh(),
      child: MasonryGridView.count(
        padding: const EdgeInsets.all(AppDimens.padding),
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.paddingM,
        crossAxisSpacing: AppDimens.paddingM,
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return _DocumentGridItem(
            document: doc,
            onTap: () => _showEditBottomSheet(context, ref, doc),
            onImageTap: () => _openDocument(context, doc),
          );
        },
      ),
    );
  }

  void _openDocument(BuildContext context, Document document) {
    final imageUrl = document.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    final fullUrl = ServerConfig.getFullImageUrl(imageUrl);
    final isPdf = fullUrl.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      context.navigateToWebView(
        webViewData: WebViewDataModel(
          webURL: fullUrl,
          webContent: null,
        ),
      );
    } else {
      context.navigateToImageViewer(imageUrl: fullUrl);
    }
  }

  void _showEditBottomSheet(
      BuildContext context, WidgetRef ref, Document document) {
    DocumentEditBottomSheet.show(
      context: context,
      document: document,
      onSubmit: ({
        required String documentId,
        String? filePath,
        String? expiryDate,
        String? uniqueCode,
      }) async {
        final success = await ref
            .read(documentViewModelProvider.notifier)
            .uploadDocument(
              documentId: documentId,
              filePath: filePath,
              expiryDate: expiryDate,
              uniqueCode: uniqueCode,
            );
        return success;
      },
    );
  }
}

class _DocumentGridItem extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback? onImageTap;

  const _DocumentGridItem({
    required this.document,
    required this.onTap,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final documentDetail = document.documentDetail;
    final statusColor = DocumentUtils.getStatusColor(document.status);
    final statusText = DocumentUtils.getStatusText(document.status);
    final isMandatory = documentDetail?.isMandatory == true;

    // Get document image URL
    final imageUrl = document.imageUrl != null && document.imageUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(document.imageUrl)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.colorBackground,
          borderRadius: BorderRadius.circular(AppDimens.paddingM),
          border: Border.all(
            color: colors.colorBackgroundGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.colorText.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Image
            GestureDetector(
              onTap: imageUrl != null && onImageTap != null
                  ? onImageTap
                  : null,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.paddingM),
                  topRight: Radius.circular(AppDimens.paddingM),
                ),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildPlaceholder(colors),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholder(colors),
                        )
                      : _buildPlaceholder(colors),
                ),
              ),
            ),
            // Document Info
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Name with required asterisk
                  Row(
                    children: [
                      Flexible(
                        child: AppText.body(
                          documentDetail?.name ?? '',
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMandatory) ...[
                        const SizedBox(width: 2),
                        Text(
                          '*',
                          style: TextStyle(
                            color: colors.colorWarning,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingS,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AppText.caption(
                      statusText,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Unique Code if exists
                  if (document.uniqueCode != null &&
                      document.uniqueCode!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingS),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: colors.colorText,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: AppText.caption(
                            document.uniqueCode!,
                            color: colors.colorText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Expiry Date if exists
                  if (document.expiryDate != null &&
                      document.expiryDate!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 12,
                          color: colors.colorText,
                        ),
                        const SizedBox(width: 4),
                        AppText.caption(
                          DocumentUtils.formatExpiryDate(document.expiryDate),
                          color: colors.colorText,
                        ),
                      ],
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

  Widget _buildPlaceholder(dynamic colors) {
    return Container(
      color: colors.colorBackgroundGray,
      child: Center(
        child: Icon(
          Icons.description_outlined,
          size: 40,
          color: colors.colorText,
        ),
      ),
    );
  }
}
