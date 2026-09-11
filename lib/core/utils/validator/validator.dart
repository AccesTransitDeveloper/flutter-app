import '../../../models/responses/auth/entity_detail_response.dart';

/// Global validator configuration
class ValidatorConfig {
  static String passwordRegex = '';
  static PasswordRule? passwordRule;
  static int phoneNumberMinLength = 6;
  static int phoneNumberMaxLength = 12;
  static const int cancellationReasonTextLength = 150;
  static int resendOtpTime = 30;
  static String timeFormat = 'hh:mm a';

  /// Update config from entity detail response
  static void updateFromSetting(Setting? setting) {
    if (setting == null) return;

    if (setting.passwordRule != null) {
      passwordRule = setting.passwordRule;
      passwordRegex = setting.passwordRule?.regEx ?? '';
    }
    if (setting.minPhoneLength != null) {
      phoneNumberMinLength = setting.minPhoneLength!;
    }
    if (setting.maxPhoneLength != null) {
      phoneNumberMaxLength = setting.maxPhoneLength!;
    }
    if (setting.entitySetting?.secOtpResendInterval != null) {
      resendOtpTime = setting.entitySetting!.secOtpResendInterval!;
    }
    if (setting.timeFormat != null) {
      timeFormat = setting.timeFormat!;
    }
  }
}

/// Validation result
class ValidationResult {
  final bool status;

  const ValidationResult(this.status);
}

/// Validator utility class
class Validator {
  Validator._();

  static ValidationResult validFirstName(String firstName) {
    return ValidationResult(firstName.isNotEmpty && firstName.isValidName());
  }

  static ValidationResult validCardName(String cardName) {
    return ValidationResult(cardName.isNotEmpty && cardName.isValidCardName());
  }

  static ValidationResult validLastName(String lastName) {
    return ValidationResult(lastName.isNotEmpty && lastName.isValidName());
  }

  static ValidationResult validCancellationReason(String cancellationReason) {
    return ValidationResult(
      cancellationReason.isNotEmpty && cancellationReason.isValidCancellationReason(),
    );
  }

  static ValidationResult validCancellationReasonSelected(String cancellationReason) {
    return ValidationResult(cancellationReason.isNotEmpty);
  }

  static ValidationResult validEmail(String email) {
    return ValidationResult(email.isNotEmpty);
  }

  static ValidationResult validEmailFormat(String email) {
    return ValidationResult(email.isNotEmpty && email.isValidEmail());
  }

  static ValidationResult validCountryCode(String countryCode) {
    return ValidationResult(countryCode.isNotEmpty);
  }

  static ValidationResult validPhoneNumber(String phoneNumber) {
    return ValidationResult(phoneNumber.isNotEmpty);
  }

  static ValidationResult validPhoneNumberFormat(String phoneNumber) {
    return ValidationResult(phoneNumber.isNotEmpty && phoneNumber.isValidPhoneNumber());
  }

  static ValidationResult validPhoneNumberFormatForLogin(String phoneNumber) {
    return ValidationResult(phoneNumber.isNotEmpty && phoneNumber.isValidPhoneNumberForLogin());
  }

  static ValidationResult validPassword(String password) {
    return ValidationResult(password.isNotEmpty);
  }

  static ValidationResult validPasswordFormat(String password) {
    return ValidationResult(password.isNotEmpty && password.isValidPassword());
  }

  static ValidationResult validReferralCode(String referralCode) {
    return ValidationResult(referralCode.isNotEmpty);
  }

  static ValidationResult validOtp(String otp) {
    return ValidationResult(otp.isNotEmpty && otp.length >= 6);
  }

  static ValidationResult validCardNumber(String cardNumber) {
    return ValidationResult(cardNumber.isNotEmpty && cardNumber.length >= 13 && cardNumber.length <= 19);
  }

  static ValidationResult validExpiryDate(String expiryDate) {
    return ValidationResult(expiryDate.isNotEmpty && expiryDate.isValidDateExpiryFormat());
  }

  static ValidationResult validCvv(String cvv) {
    return ValidationResult(cvv.isNotEmpty && cvv.isValidCVV());
  }

  static ValidationResult validVehicleTypeSelected(bool isSelected) {
    return ValidationResult(isSelected);
  }

  static ValidationResult validAmount(String amount) {
    return ValidationResult(amount.isNotEmpty && amount.isValidAmount());
  }

  static ValidationResult validId(String id) {
    return ValidationResult(id.isNotEmpty && id.isValidId());
  }
}

/// String extension methods for validation
extension StringValidation on String {
  bool isValidName() {
    return isNotEmpty && trim().split('').every((char) => RegExp(r'[a-zA-Z]').hasMatch(char));
  }

  bool isValidCardName() {
    return isNotEmpty && trim().split('').every((char) => RegExp(r'[a-zA-Z\s]').hasMatch(char));
  }

  bool isValidCancellationReason() {
    return isNotEmpty && length <= ValidatorConfig.cancellationReasonTextLength;
  }

  bool isValidEmail() {
    final emailPattern = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,64}');
    return isNotEmpty && emailPattern.hasMatch(this);
  }

  bool isValidPhoneNumber() {
    return isNotEmpty &&
        length >= ValidatorConfig.phoneNumberMinLength &&
        length <= ValidatorConfig.phoneNumberMaxLength &&
        split('').every((char) => RegExp(r'[0-9]').hasMatch(char));
  }

  bool isValidPhoneNumberForLogin() {
    return isNotEmpty &&
        length >= 6 &&
        length <= 12 &&
        split('').every((char) => RegExp(r'[0-9]').hasMatch(char));
  }

  bool isValidPassword() {
    try {
      final regex = ValidatorConfig.passwordRegex.isNotEmpty
          ? RegExp(ValidatorConfig.passwordRegex)
          : RegExp(r'^.{6,}$');
      return isNotEmpty && regex.hasMatch(this);
    } catch (e) {
      return isNotEmpty && RegExp(r'^.{6,}$').hasMatch(this);
    }
  }

  String passwordValidationMessage() {
    final rules = ValidatorConfig.passwordRule;
    final minLength = rules?.minLength ?? 6;

    final errors = <String>[];

    if (length < minLength) {
      errors.add('at least $minLength characters long');
    }

    if ((rules?.requireNumbers ?? false) && !contains(RegExp(r'[0-9]'))) {
      errors.add('at least one number');
    }

    if ((rules?.requireUppercase ?? false) && !contains(RegExp(r'[A-Z]'))) {
      errors.add('at least one uppercase letter');
    }

    if ((rules?.requireLowercase ?? false) && !contains(RegExp(r'[a-z]'))) {
      errors.add('at least one lowercase letter');
    }

    if (rules?.requireSpecial ?? false) {
      final specialCharRegex = RegExp(r'''[!"#\$%&'()*+,\-./:;<=>?@\[\]^_`{|}~₹€£¥§©®™°±²³µ¶·¸¹¼½¾¿×÷]''');
      if (!specialCharRegex.hasMatch(this)) {
        errors.add('at least one special character');
      }
    }

    if (errors.isEmpty) {
      return '';
    } else {
      return 'Password must have ${errors.join(', ')}';
    }
  }

  String generateHiddenPhoneNumber() {
    final visibleLength = length - 4;
    final hiddenLength = length - visibleLength;
    final buffer = StringBuffer();
    for (var i = 0; i < visibleLength; i++) {
      buffer.write('*');
    }
    buffer.write(substring(length - hiddenLength));
    return buffer.toString();
  }

  String generateHiddenEmail() {
    final emailParts = split('@');
    if (emailParts.length >= 2) {
      final hiddenLength = emailParts.first.length - 1;
      final buffer = StringBuffer();
      if (hiddenLength <= 0) {
        buffer.write(emailParts.first);
      } else {
        buffer.write(emailParts.first[0]);
      }
      for (var i = 0; i < hiddenLength; i++) {
        buffer.write('*');
      }
      buffer.write('@${emailParts.last}');
      return buffer.toString();
    }
    return this;
  }

  bool isValidCVV() {
    final regex = RegExp(r'^\d{3,4}$');
    return isNotEmpty && regex.hasMatch(this);
  }

  bool isValidDateExpiryFormat() {
    try {
      final parts = split('/');
      if (parts.length != 2) return false;

      final month = int.tryParse(parts[0]);
      var year = int.tryParse(parts[1]);

      if (month == null || year == null) return false;
      if (month < 1 || month > 12) return false;

      // Convert 2-digit year to 4-digit
      if (year < 100) {
        year += 2000;
      }

      final now = DateTime.now();
      final expiryDate = DateTime(year, month + 1, 0); // Last day of expiry month

      return expiryDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  bool isValidAmount() {
    final regex = RegExp(r'^[0-9]*\.?[0-9]+$');
    return regex.hasMatch(this);
  }

  bool isValidId() {
    final specialCharactersRegex = RegExp(r'[^a-zA-Z0-9]');
    return !_containsIllegalCharacters() && !specialCharactersRegex.hasMatch(this);
  }

  bool _containsIllegalCharacters() {
    for (var i = 0; i < length; i++) {
      final code = codeUnitAt(i);

      // Check for surrogate pairs (emoji ranges)
      if (code >= 0xd800 && code <= 0xdbff) {
        if (i + 1 < length) {
          final ls = codeUnitAt(i + 1);
          final uc = ((code - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
          if (uc >= 0x1d000 && uc <= 0x1f77f) {
            return true;
          }
        }
      } else if (code >= 0xd800 && code <= 0xdfff) {
        // High surrogate
        if (i + 1 < length && codeUnitAt(i + 1) == 0x20e3) {
          return true;
        }
      } else {
        // Non surrogate
        if (code >= 0x2100 && code <= 0x27ff) return true;
        if (code >= 0x2B05 && code <= 0x2b07) return true;
        if (code >= 0x2934 && code <= 0x2935) return true;
        if (code >= 0x3297 && code <= 0x3299) return true;
        if (code == 0xa9 ||
            code == 0xae ||
            code == 0x303d ||
            code == 0x3030 ||
            code == 0x2b55 ||
            code == 0x2b1c ||
            code == 0x2b1b ||
            code == 0x2b50) {
          return true;
        }
      }
    }
    return false;
  }
}
