import 'package:flutter/services.dart';

class CardUtils {
  /// Validates card number using Luhn algorithm
  static String? validateCardNum(String? input) {
    if (input == null || input.isEmpty) {
      return "Card number required";
    }

    String cleaned = getCleanedNumber(input);

    if (cleaned.length < 13 || cleaned.length > 19) {
      return "Invalid card number";
    }

    // Luhn Algorithm
    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      sum += digit;
      alternate = !alternate;
    }

    if (sum % 10 != 0) {
      return "Invalid card number";
    }

    return null;
  }

  static String getCleanedNumber(String text) {
    return text.replaceAll(RegExp(r"[^0-9]"), '');
  }

  /// Detects card type from number
  static String? detectCardType(String number) {
    String cleaned = getCleanedNumber(number);
    if (cleaned.isEmpty) return null;

    // Visa: starts with 4
    if (cleaned.startsWith('4')) return 'Visa';

    // Mastercard: 51-55 or 2221-2720
    if (cleaned.startsWith(RegExp(r'^5[1-5]'))) return 'Mastercard';
    if (cleaned.length >= 4) {
      int first4 = int.tryParse(cleaned.substring(0, 4)) ?? 0;
      if (first4 >= 2221 && first4 <= 2720) return 'Mastercard';
    }

    // American Express: 34 or 37
    if (cleaned.startsWith('34') || cleaned.startsWith('37')) return 'Amex';

    // RuPay: 60, 65, 81, 82, 508
    if (cleaned.startsWith('60') ||
        cleaned.startsWith('65') ||
        cleaned.startsWith('81') ||
        cleaned.startsWith('82')) {
      return 'RuPay';
    }
    if (cleaned.startsWith('508')) {
      return 'RuPay';
    }

    // Discover: 6011, 622126-622925, 644-649, 65
    if (cleaned.startsWith('6011')) return 'Discover';
    if (cleaned.startsWith(RegExp(r'^64[4-9]'))) return 'Discover';

    // UnionPay: 62
    if (cleaned.startsWith('62')) return 'UnionPay';

    return 'Card';
  }
}

/// Card number formatter: adds space every 4 digits, max 16 digits
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(' ', '');

    // Limit to 16 digits
    if (text.length > 16) {
      text = text.substring(0, 16);
    }

    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(text[i]);
    }

    String finalText = formatted.toString();

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
}

/// Expiry date formatter: auto-adds / after MM, validates month, handles backspace
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Handle backspace/deletion - allow it to work naturally
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String text = newValue.text.replaceAll('/', '');

    // Limit to 4 digits (MMYY)
    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    // Validate month as user types
    if (text.isNotEmpty) {
      int firstDigit = int.tryParse(text[0]) ?? 0;
      // If first digit > 1, month can only be 10, 11, 12
      // So we allow it and validate on second digit
      if (firstDigit > 1) {
        // Allow 1, but next digit in month check will handle
      }
    }

    if (text.length >= 2) {
      int month = int.tryParse(text.substring(0, 2)) ?? 0;
      // Month must be 01-12
      if (month < 1 || month > 12) {
        // Don't add the invalid second digit
        text = oldValue.text.replaceAll('/', '');
        if (text.length > 1) {
          text = text.substring(0, 1);
        }
      }
    }

    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        formatted.write('/');
      }
      formatted.write(text[i]);
    }

    String finalText = formatted.toString();

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
}

/// UPI PSP handles - real, verified handles used in India
class UpiUtils {
  static const List<String> validPspHandles = [
    // Google Pay
    '@okaxis', '@okicici', '@oksbi', '@okhdfcbank', '@okbizaxis', '@okbizicici',

    // PhonePe
    '@ybl', '@ibl', '@axl',

    // Paytm
    '@paytm',

    // BHIM/Other UPI Apps
    '@upi', '@uboi', '@boi', '@pnb', '@cnrb', '@sbi', '@federal', '@rbl',
    '@indianbank', '@citi', '@sc', '@hsbc', '@icici', '@kotak', '@dbsbank',

    // Amazon Pay
    '@apl', '@axisb',

    // WhatsApp Pay
    '@wa',

    // Airtel Payments Bank
    '@airtel',

    // JioPay
    '@jio',
  ];

  static bool isValidPspHandle(String upiId) {
    String lower = upiId.toLowerCase();
    return validPspHandles.any((handle) => lower.endsWith(handle));
  }

  static String? validateUpiId(String? value) {
    if (value == null || value.isEmpty) return "UPI ID required";

    // Basic format check
    if (!RegExp(r'^[\w\.\-]+@[\w]+$').hasMatch(value)) {
      return "Invalid format (e.g. user@oksbi)";
    }

    // Check against valid PSP handles
    if (!isValidPspHandle(value)) {
      return "Invalid UPI handle";
    }

    return null;
  }
}
