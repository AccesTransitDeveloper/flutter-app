import 'payment_interface.dart';

/// PayStack payment manager implementation
class PayStackManager implements PaymentInterface {
  @override
  void initPaymentSdk(String publicKey) {
    // Use if needed
  }

  /// Create card intent
  /// @param card : CardDetails
  /// @param addCardIntentResponse : Intent from addCardIntent API
  /// We need to use web view to open card intent
  @override
  void createCardIntent({
    CardDetails? card,
    Intent? addCardIntentResponse,
    required PaymentResultCallback callback,
  }) {
    if (addCardIntentResponse != null) {
      callback.onCardMethodCreated(
        paymentMethodId: null,
        addCardIntentResponse: addCardIntentResponse,
      );
    }
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
