import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  DecimalTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final RegExp regex = RegExp(r'^[0-9]*\.?[0-9]*$');
    if (!regex.hasMatch(newValue.text)) return oldValue;
    final double? value = double.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value < min || value > max) return oldValue;
    return newValue;
  }
}

class IntegerTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  IntegerTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final RegExp regex = RegExp(r'^[0-9]*$');
    if (!regex.hasMatch(newValue.text)) return oldValue;
    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value < min || value > max) return oldValue;
    return newValue;
  }
}
