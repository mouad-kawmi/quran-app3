import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TajweedColorizer {
  static const Color maddColor = Colors.red;
  static const Color ghunnahColor = Colors.green;
  static const Color qalqalahColor = Colors.blue;
  static const Color silentColor = Colors.grey;

  static List<InlineSpan> colorize(String text, TextStyle baseStyle, {GestureRecognizer? recognizer}) {
    List<InlineSpan> spans = [];
    int i = 0;

    while (i < text.length) {
      String char = text[i];
      String? nextChar = (i + 1 < text.length) ? text[i + 1] : null;

      // Madd (~)
      if (char == 'ٓ' || char == 'ۤ') {
        spans.add(TextSpan(text: char, style: baseStyle.copyWith(color: maddColor), recognizer: recognizer));
        i++;
        continue;
      }

      // Ghunnah: Meem or Noon with Shaddah
      if ((char == 'م' || char == 'ن') && nextChar == 'ّ') {
        spans.add(TextSpan(text: '$char$nextChar', style: baseStyle.copyWith(color: ghunnahColor), recognizer: recognizer));
        i += 2;
        continue;
      }

      // Qalqalah: Qaf, Taa, Baa, Jeem, Daal with Sukoon
      if (['ق', 'ط', 'ب', 'ج', 'د'].contains(char) && nextChar == 'ْ') {
        spans.add(TextSpan(text: '$char$nextChar', style: baseStyle.copyWith(color: qalqalahColor), recognizer: recognizer));
        i += 2;
        continue;
      }

      // Default
      spans.add(TextSpan(text: char, style: baseStyle, recognizer: recognizer));
      i++;
    }

    return spans;
  }
}
