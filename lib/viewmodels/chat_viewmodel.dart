import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/socket_constants.dart';
import '../core/localization/app_strings.dart';
import '../core/managers/socket_manager.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../data/api/response_state.dart';
import '../data/api/server_config.dart';
import '../data/repository/socket_repository.dart';
import '../models/chat/chat_models.dart';
import '../models/responses/auth/entity_detail_response.dart';

/// State for the Chat screen
class ChatState {
  final bool isLoading;
  final Map<String, List<ChatMessage>> finalChatMap;
  final bool isScrollToBottom;
  final String message;
  final List<String> documentTypeList;
  final int? selectedDocumentTypeIndex;
  final bool showDocumentTypeBottomSheet;
  final bool? isShowDocumentImage;
  final bool? isShowDocumentCamera;
  final String? documentPath;
  final String documentTypeSelectedOption;
  final String? profileImage;
  final String? profileImageUri;
  final bool? isNeedToShowPermissionDialog;
  final bool isPermissionGranted;
  final bool isNavigateBack;

  const ChatState({
    this.isLoading = false,
    this.finalChatMap = const {},
    this.isScrollToBottom = false,
    this.message = '',
    this.documentTypeList = const [],
    this.selectedDocumentTypeIndex,
    this.showDocumentTypeBottomSheet = false,
    this.isShowDocumentImage,
    this.isShowDocumentCamera,
    this.documentPath,
    this.documentTypeSelectedOption = '',
    this.profileImage,
    this.profileImageUri,
    this.isNeedToShowPermissionDialog = false,
    this.isPermissionGranted = false,
    this.isNavigateBack = false,
  });

  ChatState copyWith({
    bool? isLoading,
    Map<String, List<ChatMessage>>? finalChatMap,
    bool? isScrollToBottom,
    String? message,
    List<String>? documentTypeList,
    int? selectedDocumentTypeIndex,
    bool? showDocumentTypeBottomSheet,
    bool? isShowDocumentImage,
    bool? isShowDocumentCamera,
    String? documentPath,
    String? documentTypeSelectedOption,
    String? profileImage,
    String? profileImageUri,
    bool? isNeedToShowPermissionDialog,
    bool? isPermissionGranted,
    bool? isNavigateBack,
    bool clearSelectedDocumentTypeIndex = false,
    bool clearProfileImage = false,
    bool clearIsShowDocumentImage = false,
    bool clearIsShowDocumentCamera = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      finalChatMap: finalChatMap ?? this.finalChatMap,
      isScrollToBottom: isScrollToBottom ?? this.isScrollToBottom,
      message: message ?? this.message,
      documentTypeList: documentTypeList ?? this.documentTypeList,
      selectedDocumentTypeIndex: clearSelectedDocumentTypeIndex
          ? null
          : (selectedDocumentTypeIndex ?? this.selectedDocumentTypeIndex),
      showDocumentTypeBottomSheet:
          showDocumentTypeBottomSheet ?? this.showDocumentTypeBottomSheet,
      isShowDocumentImage: clearIsShowDocumentImage
          ? null
          : (isShowDocumentImage ?? this.isShowDocumentImage),
      isShowDocumentCamera: clearIsShowDocumentCamera
          ? null
          : (isShowDocumentCamera ?? this.isShowDocumentCamera),
      documentPath: documentPath ?? this.documentPath,
      documentTypeSelectedOption:
          documentTypeSelectedOption ?? this.documentTypeSelectedOption,
      profileImage:
          clearProfileImage ? null : (profileImage ?? this.profileImage),
      profileImageUri: profileImageUri ?? this.profileImageUri,
      isNeedToShowPermissionDialog:
          isNeedToShowPermissionDialog ?? this.isNeedToShowPermissionDialog,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isNavigateBack: isNavigateBack ?? this.isNavigateBack,
    );
  }
}

/// ViewModel for the Chat screen
class ChatViewModel extends StateNotifier<ChatState> {
  final SocketManager _socketManager;
  final SocketRepository _socketRepository;
  final SharedPreferenceManager _sharedPref;

  Entity? _entity;
  String _receiverImage = '';
  String _chatType = '';
  String _referenceId = '';
  String _chatId = '';
  int _currentPage = -1;
  int _nextPage = -1;
  final List<ChatMessage> _messageList = [];
  bool _isReadMessage = true;
  bool _lastItemVisible = true;

  final List<String> _documentTypeList = [
    getString(appStr.descriptionCamera, 'description_camera'),
    getString(appStr.descriptionImage, 'description_image'),
  ];

  ChatViewModel(
    this._socketManager,
    this._socketRepository,
    this._sharedPref,
  ) : super(const ChatState()) {
    _init();
  }

  void _init() {
    _entity = _sharedPref.getEntity();
    state = state.copyWith(documentTypeList: _documentTypeList);
  }

  /// Initialize chat with config
  void fetchMessages(ChatConfig chatConfig) {
    if (_chatId.isNotEmpty && _referenceId.isNotEmpty) {
      return;
    }

    _chatType = chatConfig.chatType ?? '';
    _chatId = chatConfig.chatId ?? '';
    _referenceId = chatConfig.referenceId ?? '';
    _receiverImage = chatConfig.receiverImage ?? '';

    _emitChatSocketEvent();
  }

  /// Update message text
  void onMessageChange(String message) {
    state = state.copyWith(message: message);
  }

  /// Handle scroll event
  void onScroll() {
    _lastItemVisible = false;
  }

  /// Handle first item visible (load more)
  void onFirstItemVisible() {
    _lastItemVisible = false;
    if (!state.isLoading && _nextPage > 1) {
      _loadNextPage();
    }
  }

  /// Handle last item visible
  void onLastItemVisible() {
    _lastItemVisible = true;
    if (_isReadMessage) {
      _readMessage();
      _isReadMessage = false;
    }
    state = state.copyWith(isScrollToBottom: false);
  }

  /// Handle send message click
  void onSendMessageClick() {
    if (state.message.trim().isNotEmpty && state.profileImage == null) {
      _sendMessage();
    } else if (state.profileImage != null) {
      _sendImage();
    }
  }

  /// Handle attach click
  void onAttachClick() {
    state = state.copyWith(showDocumentTypeBottomSheet: true);
  }

  /// Dismiss document type bottom sheet
  void dismissDocumentTypeBottomSheet() {
    state = state.copyWith(
      showDocumentTypeBottomSheet: !state.showDocumentTypeBottomSheet,
    );
  }

  /// Handle document type option change
  void onDocumentTypeOptionChange(String option, int index) {
    state = state.copyWith(
      documentTypeSelectedOption: option,
      selectedDocumentTypeIndex: index,
    );
  }

  /// Handle document type selected
  void onDocumentTypeSelected() {
    bool? isShowDocumentCamera;
    bool? isShowDocumentImage;

    switch (state.selectedDocumentTypeIndex) {
      case 0:
        isShowDocumentCamera = true;
        isShowDocumentImage = false;
        break;
      case 1:
        isShowDocumentCamera = false;
        isShowDocumentImage = true;
        break;
      default:
        isShowDocumentCamera = null;
        isShowDocumentImage = null;
    }

    if (isShowDocumentImage == null && isShowDocumentCamera == null) {
      return;
    }

    state = state.copyWith(
      showDocumentTypeBottomSheet: !state.showDocumentTypeBottomSheet,
      isShowDocumentImage: isShowDocumentImage,
      isShowDocumentCamera: isShowDocumentCamera,
    );
  }

  /// Handle selected document type (after picking)
  void handleSelectedDocumentType() {
    state = state.copyWith(
      clearIsShowDocumentCamera: true,
      clearIsShowDocumentImage: true,
      documentTypeSelectedOption: '',
    );
  }

  /// Handle document image change
  void onChangeDocumentImage(String? documentImage) {
    if (documentImage != null) {
      state = state.copyWith(
        profileImage: documentImage,
        clearSelectedDocumentTypeIndex: true,
        showDocumentTypeBottomSheet: false,
        clearIsShowDocumentImage: true,
      );
    }
  }

  /// Clear selected image
  void clearImage() {
    state = state.copyWith(clearProfileImage: true);
  }

  /// Handle permission check
  void onPermissionCheckAndCallFunction() {
    state = state.copyWith(isNeedToShowPermissionDialog: true);
  }

  /// Handle permission result
  void onPermissionGranted(bool isGranted) {
    state = state.copyWith(isPermissionGranted: isGranted);
  }

  // ============= Private Methods =============

  void _sendImage() async {
    if (state.profileImage == null) return;

    final imagePath = state.profileImage!;
    state = state.copyWith(
      isLoading: true,
      clearProfileImage: true,
    );

    final response = await _socketRepository.chatAttachment(
      chatId: _chatId,
      referenceId: _referenceId,
      chatType: _chatType,
      imagePath: imagePath,
    );

    switch (response) {
      case Success():
        state = state.copyWith(
          isLoading: false,
          clearProfileImage: true,
        );
        break;
      case Error():
        state = state.copyWith(isLoading: false);
        break;
      case Loading():
        break;
    }
  }

  void _sendMessage() {
    final request = SocketChatMessageRequest(
      chatId: _chatId,
      referenceId: _referenceId,
      message: state.message,
      chatType: _chatType,
    );

    _socketManager.emitEvent(
      SocketConstants.eventChatMessage,
      data: request.toJson(),
      ackCallback: (ackData) {
        debugPrint('🗨️ ChatViewModel - CHAT_MESSAGE ack: $ackData');
        try {
          final json = ackData is Map<String, dynamic>
              ? ackData
              : jsonDecode(ackData.toString()) as Map<String, dynamic>;
          final response = SocketChatMessageResponse.fromJson(json);
          if (response.success == false) {
            state = state.copyWith(isNavigateBack: true);
          }
        } catch (e) {
          debugPrint('🗨️ ChatViewModel - Error parsing ack: $e');
        }
      },
    );
  }

  void _getMessage() {
    _socketManager.listenEvent(SocketConstants.eventChatMessage, (data) {
      debugPrint('🗨️ ChatViewModel - CHAT_MESSAGE received: $data');

      try {
        final response = SocketChatMessageResponse.fromJson(
          data is Map<String, dynamic>
              ? data
              : jsonDecode(data.toString()) as Map<String, dynamic>,
        );

        if (response.referenceId != _referenceId) {
          return;
        }

        _chatId = response.chatId ?? _chatId;

        final message = response.message;
        if (message != null) {
          final chatMessage = ChatMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_${identityHashCode(Object())}',
            image: _buildImageUrl(
              message.type == EntityType.customer
                  ? _entity?.imageUrl
                  : _receiverImage,
            ),
            message: message.messageType == AttachmentsType.text
                ? message.message
                : _buildImageUrl(message.message),
            isSender: message.type == EntityType.customer,
            createdAt: message.createdAt,
            dateTime: _convertUtcToLocalTime(message.createdAt ?? ''),
            messageType: message.messageType,
          );

          _messageList.add(chatMessage);

          if (_messageList.length <= 1) {
            _sortMessageGroupByDate();
          } else {
            final lastKey = state.finalChatMap.keys.lastOrNull;
            final finalChatMap =
                Map<String, List<ChatMessage>>.from(state.finalChatMap);
            if (lastKey != null) {
              final tempList = List<ChatMessage>.from(
                finalChatMap[lastKey] ?? [],
              );
              tempList.add(chatMessage);
              finalChatMap[lastKey] = tempList;
            }

            final isScrollToBottom =
                message.type == EntityType.customer || _lastItemVisible;
            final sendMessage = state.message;

            state = state.copyWith(
              finalChatMap: finalChatMap,
              message: message.type == EntityType.driver ? sendMessage : '',
              isScrollToBottom: isScrollToBottom,
            );
          }

          if (!_isReadMessage) {
            _isReadMessage = message.type != EntityType.customer;
          }
          _readMessage();
        }
      } catch (e) {
        debugPrint('🗨️ ChatViewModel - Error parsing message: $e');
      }
    });
  }

  void _readMessage() {
    final request = SocketChatMessageReadRequest(chatId: _chatId);
    _socketManager.emitEvent(
      SocketConstants.eventChatMessageRead,
      data: request.toJson(),
    );
  }

  void _getAllMessages() {
    state = state.copyWith(isLoading: true);

    final request = SocketChatMessageFetchRequest(
      chatId: _chatId,
      uniqueId: _currentPage,
    );

    _socketManager.emitEvent(
      SocketConstants.eventChatMessagesFetch,
      data: request.toJson(),
      ackCallback: (ackData) {
        debugPrint('🗨️ ChatViewModel - CHAT_MESSAGES_FETCH ack: $ackData');
        try {
          final json = ackData is Map<String, dynamic>
              ? ackData
              : jsonDecode(ackData.toString()) as Map<String, dynamic>;
          final response = SocketChatMessageFetchResponse.fromJson(json);

          _nextPage = response.messages?.firstOrNull?.uniqueId ?? -1;

          var messages = response.messages ?? [];

          if (_currentPage != -1) {
            messages = messages.reversed.toList();
          } else {
            _messageList.clear();
          }

          for (final message in messages) {
            final chatMessage = ChatMessage(
              id: '${DateTime.now().millisecondsSinceEpoch}_${identityHashCode(Object())}',
              image: _buildImageUrl(
                message.type == EntityType.customer
                    ? _entity?.imageUrl
                    : _receiverImage,
              ),
              message: message.messageType == AttachmentsType.text
                  ? message.message
                  : _buildImageUrl(message.message),
              isSender: message.type == EntityType.customer,
              createdAt: message.createdAt,
              dateTime: _convertUtcToLocalTime(message.createdAt ?? ''),
              messageType: message.messageType,
            );

            if (_currentPage == -1) {
              _messageList.add(chatMessage);
            } else {
              _messageList.insert(0, chatMessage);
            }
          }

          _sortMessageGroupByDate();

          state = state.copyWith(
            isLoading: false,
            isScrollToBottom: _currentPage == -1,
          );
        } catch (e) {
          debugPrint('🗨️ ChatViewModel - Error parsing messages: $e');
          state = state.copyWith(isLoading: false);
        }
      },
    );
  }

  void _emitChatSocketEvent() {
    final request = SocketJoinChatRequest(
      referenceId: _referenceId,
      chatType: _chatType,
    );

    _socketManager.emitEvent(
      SocketConstants.eventJoinChat,
      data: request.toJson(),
      ackCallback: (ackData) {
        debugPrint('🗨️ ChatViewModel - JOIN_CHAT ack: $ackData');
        try {
          final json = ackData is Map<String, dynamic>
              ? ackData
              : jsonDecode(ackData.toString()) as Map<String, dynamic>;
          final response = SocketJoinChatResponse.fromJson(json);
          _chatId = response.chatId ?? _chatId;

          // Always listen for new messages
          _getMessage();

          if (_chatId.isEmpty) {
            // No existing chat — show empty state
            debugPrint('🗨️ ChatViewModel - No chatId, skipping message fetch');
            return;
          }

          _getAllMessages();
          _readMessage();
        } catch (e) {
          debugPrint('🗨️ ChatViewModel - Error parsing join chat: $e');
        }
      },
    );
  }

  void _loadNextPage() {
    _currentPage = _nextPage;
    _getAllMessages();
  }

  void _sortMessageGroupByDate() {
    final tempChatMap = <String, List<ChatMessage>>{};

    for (final message in _messageList) {
      final date = _getFormattedDate(message.createdAt ?? '');
      if (date.isNotEmpty) {
        if (!tempChatMap.containsKey(date)) {
          tempChatMap[date] = [];
        }
        tempChatMap[date]!.add(message);
      }
    }

    // Sort by date
    final sortedKeys = tempChatMap.keys.toList()..sort();
    final sortedMap = <String, List<ChatMessage>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = tempChatMap[key]!;
    }

    state = state.copyWith(finalChatMap: sortedMap, message: '');
  }

  String _getFormattedDate(String utcDateTime) {
    if (utcDateTime.isEmpty) return '';

    try {
      final utcDate = DateTime.parse(utcDateTime);
      final localDate = utcDate.toLocal();
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      if (_isSameDay(localDate, now)) {
        return getString(appStr.descriptionToday, 'description_today');
      } else if (_isSameDay(localDate, yesterday)) {
        return getString(appStr.descriptionYesterday, 'description_yesterday');
      } else {
        return '${localDate.day.toString().padLeft(2, '0')} ${_getMonthName(localDate.month)} ${localDate.year}';
      }
    } catch (e) {
      return '';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String? _convertUtcToLocalTime(String utcDateTime) {
    if (utcDateTime.isEmpty) return null;

    try {
      final utcDate = DateTime.parse(utcDateTime);
      final localDate = utcDate.toLocal();
      final hour = localDate.hour;
      final minute = localDate.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      return null;
    }
  }

  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    return ServerConfig.getFullImageUrl(imagePath);
  }

  @override
  void dispose() {
    debugPrint('🗨️ ChatViewModel - DISPOSED');
    _socketManager.offEvent(SocketConstants.eventChatMessage);
    super.dispose();
  }
}

/// Provider for ChatViewModel
final chatViewModelProvider =
    StateNotifierProvider.autoDispose<ChatViewModel, ChatState>((ref) {
  final socketManager = ref.watch(socketManagerProvider);
  final socketRepository = ref.watch(socketRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  return ChatViewModel(socketManager, socketRepository, sharedPref);
});
