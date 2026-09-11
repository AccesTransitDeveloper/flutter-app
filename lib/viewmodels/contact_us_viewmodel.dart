import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/app_strings.dart';
import '../core/localization/string_constants.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/responses/support/support_ticket_response.dart';

/// Support ticket item model for UI display
class SupportTicketItem {
  final SupportTicket? supportTicket;
  final String ticketTitle;
  final String dateTimeStr;
  final String dateStr;
  final String? status;

  SupportTicketItem({
    this.supportTicket,
    this.ticketTitle = '',
    this.dateTimeStr = '',
    this.dateStr = '',
    this.status,
  });
}

/// Contact Us screen state
class ContactUsState {
  final bool isLoading;
  final bool isDataLoading;
  final String? error;
  final String? successMessage;
  final Map<String, List<SupportTicketItem>> supportTicketMap;
  final bool showSupportTicketBottomSheet;
  final String? contactEmail;
  final String? contactPhone;

  const ContactUsState({
    this.isLoading = false,
    this.isDataLoading = false,
    this.error,
    this.successMessage,
    this.supportTicketMap = const {},
    this.showSupportTicketBottomSheet = false,
    this.contactEmail,
    this.contactPhone,
  });

  ContactUsState copyWith({
    bool? isLoading,
    bool? isDataLoading,
    String? error,
    String? successMessage,
    Map<String, List<SupportTicketItem>>? supportTicketMap,
    bool? showSupportTicketBottomSheet,
    String? contactEmail,
    String? contactPhone,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ContactUsState(
      isLoading: isLoading ?? this.isLoading,
      isDataLoading: isDataLoading ?? this.isDataLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      supportTicketMap: supportTicketMap ?? this.supportTicketMap,
      showSupportTicketBottomSheet: showSupportTicketBottomSheet ?? this.showSupportTicketBottomSheet,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }
}

/// Contact Us ViewModel
class ContactUsViewModel extends StateNotifier<ContactUsState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;
  bool _isFirstLoad = true;

  ContactUsViewModel(this._appRepository, this._sharedPref)
      : super(const ContactUsState()) {
    _loadContactDetails();
    getSupportTicketHistory();
  }

  void _loadContactDetails() {
    final setting = _sharedPref.getSetting();
    state = state.copyWith(
      contactEmail: setting?.contactDetail?.email,
      contactPhone: setting?.contactDetail?.phone,
    );
  }

  /// Get support ticket history
  Future<void> getSupportTicketHistory() async {
    if (_isFirstLoad) {
      state = state.copyWith(isDataLoading: true);
    }
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _appRepository.getSupportTicketHistory();

    switch (response) {
      case Success<SupportTicketHistoryResponse>():
        _isFirstLoad = false;
        state = state.copyWith(
          isLoading: false,
          isDataLoading: false,
          supportTicketMap: _createSupportTicketList(response.data?.supportTickets),
        );
      case Error():
        state = state.copyWith(
          isLoading: false,
          isDataLoading: false,
          error: response.error?.message ?? 'Failed to load tickets',
        );
      case Loading():
        break;
    }
  }

  /// Create support ticket list grouped by date
  Map<String, List<SupportTicketItem>> _createSupportTicketList(
      List<SupportTicket>? list) {
    if (list == null || list.isEmpty) {
      return {};
    }

    final supportTicketList = <SupportTicketItem>[];
    for (final item in list) {
      supportTicketList.add(
        SupportTicketItem(
          ticketTitle: _getTicketTitle(item),
          supportTicket: item,
          dateTimeStr: _formatDateTime(item.createdAt),
          dateStr: _formatDate(item.createdAt),
          status: item.status,
        ),
      );
    }

    // Sort by created date descending
    supportTicketList.sort((a, b) {
      final dateA = a.supportTicket?.createdAt ?? '';
      final dateB = b.supportTicket?.createdAt ?? '';
      return dateB.compareTo(dateA);
    });

    // Group by date
    final notificationMap = <String, List<SupportTicketItem>>{};
    for (final ticket in supportTicketList) {
      final dateKey = ticket.dateStr;
      if (notificationMap.containsKey(dateKey)) {
        notificationMap[dateKey]!.add(ticket);
      } else {
        notificationMap[dateKey] = [ticket];
      }
    }

    return notificationMap;
  }

  String _getTicketTitle(SupportTicket item) {
    if (item.bookingUniqueId?.isEmpty ?? true) {
      return getString(
        appStr.descriptionSupportTicketId,
        'description_support_ticket_id',
      ).replacePlaceholders({
        StringConstant.supportId: item.uniqueId?.toString() ?? '',
      });
    } else {
      return getString(
        appStr.descriptionBookingId,
        'description_booking_id',
      ).replacePlaceholders({
        StringConstant.unitValue: item.bookingUniqueId ?? '',
      });
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$day $month, ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year;
      return '$day $month $year';
    } catch (e) {
      return dateString;
    }
  }

  /// Show new ticket bottom sheet
  void showNewTicketSheet() {
    state = state.copyWith(showSupportTicketBottomSheet: true);
  }

  /// Hide new ticket bottom sheet
  void hideNewTicketSheet() {
    state = state.copyWith(showSupportTicketBottomSheet: false);
  }

  /// Send email
  Future<void> sendEmail() async {
    final email = state.contactEmail;
    if (email != null && email.isNotEmpty) {
      try {
        final uri = Uri.parse('mailto:$email');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // ignore
      }
    }
  }

  /// Make phone call
  Future<void> makeCall() async {
    final phone = state.contactPhone;
    if (phone != null && phone.isNotEmpty) {
      try {
        final uri = Uri.parse('tel:$phone');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // ignore
      }
    }
  }

  /// Refresh ticket list
  Future<void> refresh() async {
    await getSupportTicketHistory();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

/// Provider for ContactUsViewModel
final contactUsViewModelProvider =
    StateNotifierProvider.autoDispose<ContactUsViewModel, ContactUsState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  return ContactUsViewModel(appRepository, sharedPref);
});
