class AiMessage {
  final String text;
  final bool fromUser;

  const AiMessage({
    required this.text,
    required this.fromUser,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': fromUser ? 'user' : 'assistant',
      'content': text,
    };
  }
}

class OrderSuggestion {
  final String? pickup;
  final String? destination;

  const OrderSuggestion({
    this.pickup,
    this.destination,
  });

  factory OrderSuggestion.fromJson(Map<String, dynamic> json) {
    return OrderSuggestion(
      pickup: json['pickup']?.toString() ?? json['pickupAddress']?.toString(),
      destination: json['dropoff']?.toString() ??
          json['destination']?.toString() ??
          json['destinationAddress']?.toString(),
    );
  }
}

class AiReply {
  final String text;
  final OrderSuggestion? orderSuggestion;

  const AiReply({
    required this.text,
    this.orderSuggestion,
  });
}

class AiAssistantState {
  final List<AiMessage> messages;
  final bool isLoading;
  final bool isListening;
  final bool isSpeaking;
  final String? error;
  final String? retryMessage;
  final OrderSuggestion? orderSuggestion;

  const AiAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.isListening = false,
    this.isSpeaking = false,
    this.error,
    this.retryMessage,
    this.orderSuggestion,
  });

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    bool? isListening,
    bool? isSpeaking,
    String? error,
    String? retryMessage,
    OrderSuggestion? orderSuggestion,
    bool clearError = false,
    bool clearRetryMessage = false,
    bool clearOrderSuggestion = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: clearError ? null : (error ?? this.error),
      retryMessage:
          clearRetryMessage ? null : (retryMessage ?? this.retryMessage),
      orderSuggestion: clearOrderSuggestion
          ? null
          : (orderSuggestion ?? this.orderSuggestion),
    );
  }
}