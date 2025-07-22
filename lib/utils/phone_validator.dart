import 'package:flutter/services.dart';

class PhoneValidator {
  /// Validates if the phone number starts with "09" and has exactly 11 digits
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces or special characters
    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it starts with "09"
    if (!cleanNumber.startsWith('09')) {
      return 'Phone number must start with "09"';
    }

    // Check if it has exactly 11 digits
    if (cleanNumber.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }

    return null;
  }

  /// Formats the phone number as user types (09XX XXX XXXX)
  static String formatPhoneNumber(String value) {
    // Remove any non-digit characters
    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 11 digits
    if (cleanNumber.length > 11) {
      cleanNumber = cleanNumber.substring(0, 11);
    }

    // Format as 09XX XXX XXXX
    if (cleanNumber.length >= 7) {
      return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4, 7)} ${cleanNumber.substring(7)}';
    } else if (cleanNumber.length >= 4) {
      return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4)}';
    } else {
      return cleanNumber;
    }
  }

  /// Input formatter for phone number fields
  static List<TextInputFormatter> getPhoneInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11),
    ];
  }

  /// Cleans the phone number for storage (removes formatting)
  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Checks if a phone number is valid without returning error message
  static bool isValidPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    return cleanNumber.startsWith('09') && cleanNumber.length == 11;
  }
}
