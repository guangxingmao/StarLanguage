import 'package:flutter/material.dart';

Color parseColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0xFFC857;
  if (cleaned.length <= 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value);
}
