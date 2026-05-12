import 'package:flutter/services.dart';

class AutoDecimalFormatter extends TextInputFormatter {
  AutoDecimalFormatter({
    required this.integerDigits,
    required this.decimalDigits,
    required this.separator,
  });

  final int integerDigits;
  final int decimalDigits;
  final String separator;

  int get _maxDigits => integerDigits + decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final clamped =
        digits.length > _maxDigits ? digits.substring(0, _maxDigits) : digits;

    String formatted;
    if (clamped.length <= integerDigits) {
      formatted = clamped;
    } else {
      final intPart = clamped.substring(0, integerDigits);
      final decPart = clamped.substring(integerDigits);
      formatted = '$intPart$separator$decPart';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
