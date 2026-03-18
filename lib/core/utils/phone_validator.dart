/// Validates that a phone number is a normal mobile number (not toll-free, short-code, etc.)
class PhoneValidator {
  /// Returns null if valid, error message if invalid.
  static String? validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.isEmpty) return 'Please enter a valid phone number';

    // Extract country code and number
    String countryCode = '';
    String number = digits;

    if (digits.startsWith('91') && digits.length > 10) {
      countryCode = '91';
      number = digits.substring(2);
    } else if (digits.startsWith('92') && digits.length > 10) {
      countryCode = '92';
      number = digits.substring(2);
    } else if (digits.length >= 10 && digits.length <= 12) {
      number = digits.length == 10 ? digits : digits.substring(digits.length - 10);
    }

    // Too short - likely toll-free/short-code (e.g. 9153432, 1800xxx)
    if (number.length < 10) {
      return '$phone is not a valid mobile number. Toll-free and short-code numbers cannot be added. Please enter a 10-digit mobile number.';
    }

    // India (+91)
    if (countryCode == '91' || (digits.length == 10 && digits[0] != '0')) {
      if (number.length != 10) {
        return '$phone is not a valid mobile number. Toll-free and short-code numbers cannot be added. Please enter a 10-digit mobile number.';
      }
      // Toll-free: 1800, 1860, 0800
      if (number.startsWith('1800') || number.startsWith('1860') || number.startsWith('0800')) {
        return '$phone is a toll-free number. Toll-free numbers cannot be added as members. Please enter a personal mobile number.';
      }
      // Indian mobile: starts with 6, 7, 8, 9
      final firstDigit = number[0];
      if (!['6', '7', '8', '9'].contains(firstDigit)) {
        return '$phone is not a valid mobile number. Toll-free and short-code numbers cannot be added. Please enter a valid 10-digit mobile number.';
      }
    }

    // Pakistan (+92)
    if (countryCode == '92') {
      if (number.length < 10) {
        return '$phone is not a valid mobile number. Please enter a valid mobile number.';
      }
      // Pakistan mobile: typically starts with 3
      if (number[0] != '3') {
        return '$phone is not a valid mobile number. Please enter a valid mobile number.';
      }
    }

    return null;
  }

  /// Returns true if phone is valid for adding as member.
  static bool isValidMobile(String phone) => validatePhone(phone) == null;
}
