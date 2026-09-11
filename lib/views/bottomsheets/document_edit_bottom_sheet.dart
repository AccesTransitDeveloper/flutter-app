import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/document_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/api/server_config.dart';
import '../../models/responses/document/document_response.dart';
import '../../core/theme/app_theme.dart';
import '../../views/widgets/app_button.dart';
import '../../views/widgets/app_text.dart';
import '../../views/widgets/app_text_field.dart';
import 'file_picker_bottom_sheet.dart';
import 'date_picker_bottom_sheet.dart';

class DocumentEditBottomSheet extends StatefulWidget {
  final Document document;
  final Future<bool> Function({
    required String documentId,
    String? filePath,
    String? expiryDate,
    String? uniqueCode,
  }) onSubmit;

  const DocumentEditBottomSheet({
    super.key,
    required this.document,
    required this.onSubmit,
  });

  static Future<void> show({
    required BuildContext context,
    required Document document,
    required Future<bool> Function({
      required String documentId,
      String? filePath,
      String? expiryDate,
      String? uniqueCode,
    }) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentEditBottomSheet(
        document: document,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<DocumentEditBottomSheet> createState() =>
      _DocumentEditBottomSheetState();
}

class _DocumentEditBottomSheetState extends State<DocumentEditBottomSheet> {
  final _uniqueCodeController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedFilePath;
  String? _selectedExpiryDate;
  bool _isPdf = false;
  bool _isSubmitting = false;
  double _webViewHeight = 1;

  @override
  void initState() {
    super.initState();
    _uniqueCodeController.text = widget.document.uniqueCode ?? '';
    _selectedExpiryDate = widget.document.expiryDate;
  }

  @override
  void dispose() {
    _uniqueCodeController.dispose();
    super.dispose();
  }

  bool get _requiresUniqueCode =>
      widget.document.documentDetail?.isUniqueCode == true;

  bool get _requiresExpiry =>
      widget.document.documentDetail?.isExpiry == true;

  String? get _existingImageUrl {
    final imageUrl = widget.document.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ServerConfig.getFullImageUrl(imageUrl);
    }
    return null;
  }

  /// Check if document has an image (either newly selected or existing)
  bool get _hasImage =>
      _selectedFilePath != null ||
      (widget.document.imageUrl != null && widget.document.imageUrl!.isNotEmpty);

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied && mounted) {
      _showPermissionDeniedDialog('Camera');
    }
    return false;
  }

  Future<bool> _requestStoragePermission() async {
    // On Android 13+, no storage permission needed for photo picker
    if (Platform.isAndroid) {
      // For Android, image_picker handles permissions internally
      return true;
    }

    // iOS: check photo library permission
    final status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;

    final result = await Permission.photos.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied && mounted) {
      _showPermissionDeniedDialog('Photo Library');
    }
    return false;
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'Please enable $permissionName permission in settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    context.showErrorSnackBar(message);
  }

  Future<void> _pickFile() async {
    final source = await FilePickerBottomSheet.show(context);
    if (source == null || !mounted) return;

    String? filePath;

    switch (source) {
      case FilePickerSource.camera:
        final hasPermission = await _requestCameraPermission();
        if (!hasPermission || !mounted) return;

        final pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        filePath = pickedFile?.path;
        if (filePath != null) {
          setState(() {
            _selectedFilePath = filePath;
            _isPdf = false;
          });
        }
        break;

      case FilePickerSource.gallery:
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission || !mounted) return;

        final pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        filePath = pickedFile?.path;
        if (filePath != null) {
          setState(() {
            _selectedFilePath = filePath;
            _isPdf = false;
          });
        }
        break;

      case FilePickerSource.pdf:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null && result.files.single.path != null) {
          setState(() {
            _selectedFilePath = result.files.single.path;
            _isPdf = true;
          });
        }
        break;
    }
  }

  Future<void> _pickDate() async {
    final date = await DatePickerBottomSheet.show(
      context: context,
      initialDate: AppDateUtils.parse(_selectedExpiryDate),
    );

    if (date != null) {
      setState(() {
        _selectedExpiryDate = AppDateUtils.toApiDateString(date);
      });
    }
  }

  /// Validate document data before submission (matching Kotlin logic)
  bool _validateDocumentData() {
    final selectedDocument = widget.document;

    // Check if unique code is required but empty
    if (_requiresUniqueCode && _uniqueCodeController.text.trim().isEmpty) {
      _showSnackBar(getString(appStr.errorPleaseDocumentId, 'error_please_document_id'));
      return false;
    }


    // Check if expiry date is required but empty
    if (_requiresExpiry &&
        (_selectedExpiryDate == null || _selectedExpiryDate!.isEmpty)) {
      _showSnackBar(getString(appStr.errorPleaseExpiryDate, 'error_please_expiry_date'));
      return false;
    }

    // Check if image is required but empty
    if (!_hasImage) {
      _showSnackBar(getString(appStr.errorPleaseSelectImage, 'error_please_select_image'));
      return false;
    }

    // Check if data has changed (matching Kotlin isDocumentDataSame logic)
    final isSameDocumentId = _requiresUniqueCode &&
            (selectedDocument.uniqueCode?.isEmpty ?? true)
        ? false
        : selectedDocument.uniqueCode == _uniqueCodeController.text;

    final isSameExpiryDate = _requiresExpiry &&
            (selectedDocument.expiryDate?.isEmpty ?? true)
        ? false
        : DocumentUtils.formatExpiryDate(selectedDocument.expiryDate) ==
            DocumentUtils.formatExpiryDate(_selectedExpiryDate);

    final isSameImage = selectedDocument.imageUrl?.isEmpty ?? true
        ? false
        : _selectedFilePath == null; // No new file selected means using existing

    // If all data is the same, show error
    if (isSameDocumentId && isSameExpiryDate && isSameImage) {
      _showSnackBar(getString(appStr.errorPleaseUpdateDocument, 'error_please_update_document'));
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    // Validate before submission
    if (!_validateDocumentData()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Use _id field for API endpoint
    final documentId = widget.document.id ?? '';

    final success = await widget.onSubmit(
      documentId: documentId,
      filePath: _selectedFilePath,
      expiryDate: _selectedExpiryDate,
      uniqueCode: _requiresUniqueCode ? _uniqueCodeController.text.trim() : null,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.pop(context);
        context.showSnackBar(getString(appStr.successDocumentUpdated, 'success_document_updated'));
      } else {
        context.showErrorSnackBar(getString(appStr.errorDocumentUpdateFailed, 'error_document_update_failed'));
      }
    }
  }

  /// Get title based on whether adding or editing
  String _getTitle() {
    final doc = widget.document;
    final name = doc.documentDetail?.name ?? 'Document';
    final isNew = (doc.uniqueCode?.isEmpty ?? true) &&
        (doc.expiryDate?.isEmpty ?? true) &&
        (doc.imageUrl?.isEmpty ?? true);
    final addPrefix = getString(appStr.subHeadingAdd, 'sub_heading_add');
    final editPrefix = getString(appStr.subHeadingEdit, 'sub_heading_edit');
    return isNew ? '$addPrefix $name' : '$editPrefix $name';
  }

  String _wrapDescriptionHtml(String content, AppColorPalette colors) {
    final textColor =
        '#${colors.colorText.toARGB32().toRadixString(16).substring(2)}';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    font-size: 13px;
    line-height: 1.5;
    color: $textColor;
    margin: 0;
    padding: 0;
    background: transparent;
  }
  p { margin: 4px 0; }
</style>
</head>
<body>$content</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final documentDetail = widget.document.documentDetail;
    final isMandatory = documentDetail?.isMandatory == true;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.paddingL),
          topRight: Radius.circular(AppDimens.paddingL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDimens.padding,
            right: AppDimens.padding,
            top: AppDimens.paddingL,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.padding,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with required asterisk (centered)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: AppText.title(
                          _getTitle(),
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMandatory) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Document description (HTML)
                if (documentDetail?.description != null &&
                    documentDetail!.description!.isNotEmpty) ...[
                  SizedBox(
                    height: _webViewHeight,
                    child: InAppWebView(
                      initialData: InAppWebViewInitialData(
                        data: _wrapDescriptionHtml(
                            documentDetail.description!, colors),
                      ),
                      initialSettings: InAppWebViewSettings(
                        transparentBackground: true,
                        javaScriptEnabled: true,
                      ),
                      onLoadStop: (controller, url) async {
                        final height = await controller.evaluateJavascript(
                            source: 'document.body.scrollHeight');
                        if (height != null && mounted) {
                          setState(() {
                            _webViewHeight =
                                (height as num).toDouble().clamp(0, 500);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Unique Code field (if required)
                if (_requiresUniqueCode) ...[
                  Row(
                    children: [
                      AppText.caption(
                        getString(appStr.hintDocumentId, 'hint_document_id'),
                        color: colors.colorText,
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  AppTextField(
                    controller: _uniqueCodeController,
                    hintText: getString(appStr.hintUniqueId, 'hint_unique_id'),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Expiry Date field (if required)
                if (_requiresExpiry) ...[
                  Row(
                    children: [
                      AppText.caption(
                        getString(appStr.hintExpiryDate, 'hint_expiry_date'),
                        color: colors.colorText,
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.padding,
                        vertical: AppDimens.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: colors.colorBackgroundGray,
                        borderRadius:
                            BorderRadius.circular(AppDimens.buttonRadius),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText.body(
                              _selectedExpiryDate != null
                                  ? DocumentUtils.formatExpiryDate(
                                      _selectedExpiryDate)
                                  : getString(appStr.hintExpiryDate, 'hint_expiry_date'),
                              color: _selectedExpiryDate != null
                                  ? colors.colorText
                                  : colors.colorText,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            color: colors.colorText,
                            size: AppDimens.iconSizeSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Document Image
                Row(
                  children: [
                    AppText.caption(
                      getString(appStr.descriptionImage, 'description_image'),
                      color: colors.colorText,
                    ),
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingS),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: colors.colorBackgroundGray,
                      borderRadius:
                          BorderRadius.circular(AppDimens.buttonRadius),
                    ),
                    child: _buildImageContent(colors),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingXL),

                // Submit Button
                AppFilledButton(
                  text: getString(appStr.buttonSave, 'button_save'),
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(dynamic colors) {
    if (_selectedFilePath != null) {
      if (_isPdf) {
        return _buildPdfPreview(colors);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(_selectedFilePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(colors),
            ),
            Positioned(
              top: AppDimens.paddingS,
              right: AppDimens.paddingS,
              child: Container(
                padding: const EdgeInsets.all(AppDimens.paddingXS),
                decoration: BoxDecoration(
                  color: colors.colorPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  size: AppDimens.iconSizeSmall,
                  color: colors.colorButtonText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_existingImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _existingImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(colors),
              errorWidget: (context, url, error) => _buildPlaceholder(colors),
            ),
            Positioned(
              top: AppDimens.paddingS,
              right: AppDimens.paddingS,
              child: Container(
                padding: const EdgeInsets.all(AppDimens.paddingXS),
                decoration: BoxDecoration(
                  color: colors.colorPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  size: AppDimens.iconSizeSmall,
                  color: colors.colorButtonText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildPlaceholder(colors);
  }

  Widget _buildPdfPreview(dynamic colors) {
    final fileName = _selectedFilePath?.split('/').last ?? 'document.pdf';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: colors.colorBackgroundGray,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: AppDimens.paddingS),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
                  child: AppText.caption(
                    fileName,
                    color: colors.colorText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppDimens.paddingS,
            right: AppDimens.paddingS,
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingXS),
              decoration: BoxDecoration(
                color: colors.colorPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit,
                size: AppDimens.iconSizeSmall,
                color: colors.colorButtonText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(dynamic colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: colors.colorText,
        ),
        const SizedBox(height: AppDimens.paddingS),
        AppText.caption(
          getString(appStr.descriptionUploadDocument, 'description_upload_document'),
          color: colors.colorText,
        ),
      ],
    );
  }
}
