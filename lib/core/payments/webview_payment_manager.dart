import 'payment_interface.dart';

/// WebView payment manager implementation (for Razorpay and similar web-based payments)
class WebViewPaymentManager implements PaymentInterface {
  @override
  void initPaymentSdk(String publicKey) {
    // Use if needed
  }

  /// @param card : CardDetails
  /// @param addCardIntentResponse : Intent from addCardIntent API
  /// @note Razorpay doesn't have functionality to add Card
  @override
  void createCardIntent({
    CardDetails? card,
    Intent? addCardIntentResponse,
    required PaymentResultCallback callback,
  }) {
    // Use if needed
  }

  @override
  void createPaymentIntent({
    IntentPayment? intent,
    required PaymentResultCallback callback,
  }) {
    callback.onPaymentMethodCreated(
      paymentMethodId: null,
      addCardIntentResponse: intent,
    );
  }
}
