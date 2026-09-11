import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/support_ticket_request.dart';
import '../models/responses/support/support_ticket_response.dart';

/// Support Ticket Bottom Sheet state
class SupportTicketState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<SupportCategory> categoryList;
  final List<String> categoryNames;
  final SupportCategory? selectedCategory;
  final String ticketSubject;
  final String ticketMessage;
  final String ticketImage;
  final String? bookingId;
  final bool isTicketCreated;
  final bool showImagePickerSheet;
  final bool isCameraSelected;
  final bool isGallerySelected;

  const SupportTicketState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.categoryList = const [],
    this.categoryNames = const [],
    this.selectedCategory,
    this.ticketSubject = '',
    this.ticketMessage = '',
    this.ticketImage = '',
    this.bookingId,
    this.isTicketCreated = false,
    this.showImagePickerSheet = false,
    this.isCameraSelected = false,
    this.isGallerySelected = false,
  });

  SupportTicketState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<SupportCategory>? categoryList,
    List<String>? categoryNames,
    SupportCategory? selectedCategory,
    String? ticketSubject,
    String? ticketMessage,
    String? ticketImage,
    String? bookingId,
    bool? isTicketCreated,
    bool? showImagePickerSheet,
    bool? isCameraSelected,
    bool? isGallerySelected,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelectedCategory = false,
  }) {
    return SupportTicketState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      categoryList: categoryList ?? this.categoryList,
      categoryNames: categoryNames ?? this.categoryNames,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      ticketSubject: ticketSubject ?? this.ticketSubject,
      ticketMessage: ticketMessage ?? this.ticketMessage,
      ticketImage: ticketImage ?? this.ticketImage,
      bookingId: bookingId ?? this.bookingId,
      isTicketCreated: isTicketCreated ?? this.isTicketCreated,
      showImagePickerSheet: showImagePickerSheet ?? this.showImagePickerSheet,
      isCameraSelected: isCameraSelected ?? this.isCameraSelected,
      isGallerySelected: isGallerySelected ?? this.isGallerySelected,
    );
  }
}

/// Support Ticket ViewModel
class SupportTicketViewModel extends StateNotifier<SupportTicketState> {
  final AppRepository _appRepository;

  SupportTicketViewModel(this._appRepository) : super(const SupportTicketState()) {
    _loadCategories();
  }

  /// Load support ticket categories
  Future<void> _loadCategories() async {
    state = state.copyWith(isLoading: true);

    final response = await _appRepository.getSupportTicketCategories();

    switch (response) {
      case Success<SupportTicketCategoriesResponse>():
        final categories = response.data?.categories ?? [];
        final categoryNames = categories.map((c) => c.message ?? '').toList();
        state = state.copyWith(
          isLoading: false,
          categoryList: categories,
          categoryNames: categoryNames,
        );
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Failed to load categories',
        );
      case Loading():
        break;
    }
  }

  /// Select category by index
  void selectCategory(int index) {
    if (index >= 0 && index < state.categoryList.length) {
      state = state.copyWith(selectedCategory: state.categoryList[index]);
    }
  }

  /// Update ticket subject
  void updateSubject(String subject) {
    state = state.copyWith(ticketSubject: subject);
  }

  /// Update ticket message
  void updateMessage(String message) {
    state = state.copyWith(ticketMessage: message);
  }

  /// Set ticket image
  void setImage(String imagePath) {
    state = state.copyWith(
      ticketImage: imagePath,
      isCameraSelected: false,
      isGallerySelected: false,
    );
  }

  /// Set booking ID (when creating ticket from booking)
  void setBookingId(String? bookingId) {
    state = state.copyWith(bookingId: bookingId);
  }

  /// Show image picker sheet
  void showImagePicker() {
    state = state.copyWith(showImagePickerSheet: true);
  }

  /// Hide image picker sheet
  void hideImagePicker() {
    state = state.copyWith(
      showImagePickerSheet: false,
      isCameraSelected: false,
      isGallerySelected: false,
    );
  }

  /// Select camera option
  void selectCamera() {
    state = state.copyWith(
      isCameraSelected: true,
      isGallerySelected: false,
      showImagePickerSheet: false,
    );
  }

  /// Select gallery option
  void selectGallery() {
    state = state.copyWith(
      isCameraSelected: false,
      isGallerySelected: true,
      showImagePickerSheet: false,
    );
  }

  /// Reset picker selection
  void resetPickerSelection() {
    state = state.copyWith(
      isCameraSelected: false,
      isGallerySelected: false,
    );
  }

  /// Validate form data
  bool _validateForm() {
    if (state.selectedCategory == null) {
      state = state.copyWith(
        error: getString(
          appStr.errorPleaseSelectTicketCategory,
          'error_please_select_ticket_category',
        ),
      );
      return false;
    }

    if (state.ticketSubject.trim().isEmpty) {
      state = state.copyWith(
        error: getString(
          appStr.errorPleaseEnterSubject,
          'error_please_enter_subject',
        ),
      );
      return false;
    }

    if (state.ticketMessage.trim().isEmpty) {
      state = state.copyWith(
        error: getString(
          appStr.errorPleaseEnterMessage,
          'error_please_select_enter_message',
        ),
      );
      return false;
    }

    return true;
  }

  /// Submit support ticket
  Future<void> submitTicket() async {
    if (!_validateForm()) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final request = SupportTicketRequest(
      subject: state.ticketSubject,
      description: state.ticketMessage,
      category: state.selectedCategory?.key,
      bookingId: state.bookingId,
    );

    final response = await _appRepository.createSupportTicket(request);

    switch (response) {
      case Success():
        final ticketId = response.header?.id;
        if (ticketId != null && state.ticketImage.isNotEmpty) {
          await _uploadTicketImage(ticketId);
        } else {
          _onTicketCreated(response.message);
        }
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Failed to create ticket',
        );
      case Loading():
        break;
    }
  }

  /// Upload ticket image
  Future<void> _uploadTicketImage(String ticketId) async {
    final response = await _appRepository.addSupportTicketImage(
      ticketId: ticketId,
      filePath: state.ticketImage,
    );

    switch (response) {
      case Success():
        _onTicketCreated(response.message);
      case Error():
        // Even if image upload fails, ticket was created
        _onTicketCreated(response.error?.message);
      case Loading():
        break;
    }
  }

  void _onTicketCreated(String? message) {
    state = state.copyWith(
      isLoading: false,
      isTicketCreated: true,
      successMessage: message,
    );
  }

  /// Reset ticket created flag
  void resetTicketCreated() {
    state = state.copyWith(isTicketCreated: false);
  }

  /// Reset form data
  void resetForm() {
    state = state.copyWith(
      ticketSubject: '',
      ticketMessage: '',
      ticketImage: '',
      bookingId: null,
      isTicketCreated: false,
      clearSelectedCategory: true,
      clearError: true,
      clearSuccess: true,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

/// Provider for SupportTicketViewModel
final supportTicketViewModelProvider =
    StateNotifierProvider.autoDispose<SupportTicketViewModel, SupportTicketState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  return SupportTicketViewModel(appRepository);
});
