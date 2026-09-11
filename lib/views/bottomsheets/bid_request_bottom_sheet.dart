import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text.dart';

/// Bottom sheet for entering a bid amount
/// Returns the bid amount as double if confirmed, null if cancelled
class BidRequestBottomSheet extends StatefulWidget {
  final double currentPrice;
  final double minBidPrice;
  final String currencySign;
  final int decimalPointValue;
  final bool isAllowStepper;
  final double stepperAmount;
  final VoidCallback onCancel;
  final ValueChanged<double> onConfirm;

  const BidRequestBottomSheet({
    super.key,
    required this.currentPrice,
    required this.minBidPrice,
    required this.currencySign,
    required this.decimalPointValue,
    required this.isAllowStepper,
    required this.stepperAmount,
    required this.onCancel,
    required this.onConfirm,
  });

  /// Shows the bid request bottom sheet
  /// Returns the confirmed bid amount, or null if cancelled
  static Future<double?> show({
    required BuildContext context,
    required double currentPrice,
    required double minBidPrice,
    required String currencySign,
    required int decimalPointValue,
    required bool isAllowStepper,
    required double stepperAmount,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BidRequestBottomSheet(
          currentPrice: currentPrice,
          minBidPrice: minBidPrice,
          currencySign: currencySign,
          decimalPointValue: decimalPointValue,
          isAllowStepper: isAllowStepper,
          stepperAmount: stepperAmount,
          onCancel: () => Navigator.pop(context),
          onConfirm: (amount) => Navigator.pop(context, amount),
        ),
      ),
    );
  }

  @override
  State<BidRequestBottomSheet> createState() => _BidRequestBottomSheetState();
}

class _BidRequestBottomSheetState extends State<BidRequestBottomSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  late double _currentAmount;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.currentPrice;
    _controller = TextEditingController(
      text: widget.currentPrice.toStringAsFixed(widget.decimalPointValue),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _currentAmount += widget.stepperAmount;
      _controller.text =
          _currentAmount.toStringAsFixed(widget.decimalPointValue);
      _errorText = null;
    });
  }

  void _decrement() {
    final newAmount = _currentAmount - widget.stepperAmount;
    if (newAmount < widget.minBidPrice) {
      setState(() {
        _errorText =
            'Minimum bid amount is ${widget.currencySign}${widget.minBidPrice.toStringAsFixed(widget.decimalPointValue)}';
      });
      return;
    }
    setState(() {
      _currentAmount = newAmount;
      _controller.text =
          _currentAmount.toStringAsFixed(widget.decimalPointValue);
      _errorText = null;
    });
  }

  void _onConfirmPressed() {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorText = getString(
            appStr.descriptionEnterBidAmount, 'description_enter_bid_amount');
      });
      return;
    }
    if (amount < widget.minBidPrice) {
      setState(() {
        _errorText =
            'Minimum bid amount is ${widget.currencySign}${widget.minBidPrice.toStringAsFixed(widget.decimalPointValue)}';
      });
      return;
    }
    widget.onConfirm(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.colorText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.paddingS),
                child: AppText.title(
                  getString(appStr.headingBidRequest, 'heading_bid_request'),
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: AppDimens.paddingS),

              // Description
              AppText.body(
                getString(appStr.descriptionEnterBidAmount,
                    'description_enter_bid_amount'),
                fontSize: 12,
              ),

              const SizedBox(height: AppDimens.padding),

              // Amount input with optional stepper buttons
              Row(
                children: [
                  if (widget.isAllowStepper)
                    _buildStepperButton(Icons.remove, _decrement, colors),
                  if (widget.isAllowStepper)
                    const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.colorText,
                      ),
                      decoration: InputDecoration(
                        prefixText: '${widget.currencySign} ',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.buttonRadius),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.padding,
                          vertical: AppDimens.paddingM,
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed != null) {
                          _currentAmount = parsed;
                        }
                        if (_errorText != null) {
                          setState(() {
                            _errorText = null;
                          });
                        }
                      },
                    ),
                  ),
                  if (widget.isAllowStepper)
                    const SizedBox(width: AppDimens.paddingM),
                  if (widget.isAllowStepper)
                    _buildStepperButton(Icons.add, _increment, colors),
                ],
              ),

              if (_errorText != null) ...[
                const SizedBox(height: AppDimens.paddingS),
                AppText.caption(
                  _errorText!,
                  color: colors.colorWarning,
                ),
              ],

              const SizedBox(height: AppDimens.padding),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppFilledButton(
                      text: getString(
                          appStr.buttonConfirmBid, 'button_confirm_bid'),
                      onPressed: _onConfirmPressed,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: AppOutlinedButton(
                      text: 'Cancel',
                      onPressed: widget.onCancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton(
      IconData icon, VoidCallback onTap, AppColorPalette colors) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        ),
        child: Icon(icon, color: colors.colorText),
      ),
    );
  }
}
