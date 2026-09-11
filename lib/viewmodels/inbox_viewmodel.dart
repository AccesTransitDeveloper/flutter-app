import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/responses/notification/notification_response.dart';

/// Inbox screen state
class InboxState {
  final List<NotificationItem> notifications;
  final Map<String, List<NotificationItem>> groupedNotifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool endReached;
  final String? error;
  final int totalCount;

  const InboxState({
    this.notifications = const [],
    this.groupedNotifications = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.endReached = false,
    this.error,
    this.totalCount = 0,
  });

  InboxState copyWith({
    List<NotificationItem>? notifications,
    Map<String, List<NotificationItem>>? groupedNotifications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? endReached,
    String? error,
    int? totalCount,
    bool clearError = false,
  }) {
    return InboxState(
      notifications: notifications ?? this.notifications,
      groupedNotifications: groupedNotifications ?? this.groupedNotifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      endReached: endReached ?? this.endReached,
      error: clearError ? null : (error ?? this.error),
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Inbox screen ViewModel
class InboxViewModel extends StateNotifier<InboxState> {
  final AppRepository _appRepository;

  int _currentPage = 1;
  final int _limit = 10;
  bool _isFirstLoad = true;

  InboxViewModel(this._appRepository) : super(const InboxState()) {
    debugPrint('📬 InboxViewModel - initialized, calling loadNotifications');
    loadNotifications();
  }

  /// Load notifications
  Future<void> loadNotifications() async {
    debugPrint('📬 InboxViewModel - loadNotifications called, isFirstLoad: $_isFirstLoad');

    if (_isFirstLoad) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    final deviceType = Platform.isAndroid ? DeviceType.android : DeviceType.ios;
    debugPrint('📬 InboxViewModel - calling API with deviceType: $deviceType');

    final response = await _appRepository.getNotifications(
      page: _currentPage,
      limit: _limit,
      deviceType: deviceType,
      userType: UserType.customer,
      notificationType: NotificationType.push,
    );

    debugPrint('📬 InboxViewModel - API response received: ${response.runtimeType}');

    switch (response) {
      case Success<NotificationResponse>():
        final newNotifications = response.data?.notifications ?? [];
        final totalCount = response.data?.dataCount ?? 0;
        debugPrint('📬 InboxViewModel - Success: ${newNotifications.length} notifications, total: $totalCount');

        if (newNotifications.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            endReached: true,
            totalCount: totalCount,
          );
        } else {
          List<NotificationItem> allNotifications;
          if (_currentPage == 1) {
            allNotifications = newNotifications;
          } else {
            allNotifications = [...state.notifications, ...newNotifications];
          }

          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            notifications: allNotifications,
            groupedNotifications: _groupNotificationsByDate(allNotifications),
            endReached: allNotifications.length >= totalCount,
            totalCount: totalCount,
          );
          _currentPage++;
        }
        _isFirstLoad = false;

      case Error():
        debugPrint('📬 InboxViewModel - Error: ${response.error?.message}');
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: response.error?.message ?? 'Failed to load notifications',
        );
        _isFirstLoad = false;

      case Loading():
        break;
    }
  }

  /// Load more notifications (pagination)
  void loadMore() {
    if (!state.isLoading && !state.isLoadingMore && !state.endReached) {
      loadNotifications();
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    _currentPage = 1;
    _isFirstLoad = true;
    state = state.copyWith(
      notifications: [],
      groupedNotifications: {},
      endReached: false,
    );
    await loadNotifications();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Group notifications by date
  Map<String, List<NotificationItem>> _groupNotificationsByDate(
      List<NotificationItem> notifications) {
    final Map<String, List<NotificationItem>> grouped = {};

    for (final notification in notifications) {
      if (notification.createdAt != null) {
        final dateKey = AppDateUtils.formatString(
          notification.createdAt,
          DateFormat.dateFormatWithSpace,
        );
        if (dateKey.isNotEmpty) {
          grouped.putIfAbsent(dateKey, () => []);
          grouped[dateKey]!.add(notification);
        }
      }
    }

    return grouped;
  }
}

/// Provider for InboxViewModel
final inboxViewModelProvider =
    StateNotifierProvider.autoDispose<InboxViewModel, InboxState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  return InboxViewModel(appRepository);
});
