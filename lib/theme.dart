import 'package:flutter/material.dart';

/// The five block colours. The same in light and dark mode.
const List<Color> kBlockColors = [
  Color(0xFFFF6B5B), // coral
  Color(0xFFFFC24D), // amber
  Color(0xFF2EC4B6), // teal
  Color(0xFF4DA3FF), // sky
  Color(0xFF8B7CFF), // violet
];

const Color kCoral = Color(0xFFFF6B5B);
const Color kAmber = Color(0xFFFFC24D);
const Color kInk = Color(0xFF14122B);

/// Colours that change between light and dark mode.
class CubooColors {
  const CubooColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.board,
    required this.emptyCell,
    required this.text,
    required this.muted,
    required this.bestText,
    required this.buttonShadow,
    required this.cardShadow,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color board;
  final Color emptyCell;
  final Color text;
  final Color muted;
  final Color bestText;
  final Color buttonShadow;
  final Color cardShadow;

  static const CubooColors dark = CubooColors(
    bg: Color(0xFF14122B),
    surface: Color(0xFF1F1C45),
    surfaceAlt: Color(0xFF2A2659),
    board: Color(0xFF1B1840),
    emptyCell: Color(0xFF221F4D),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFB4B1E0),
    bestText: Color(0xFFFFC24D),
    buttonShadow: Color(0xFFC94A3C),
    cardShadow: Color(0x00000000),
  );

  static const CubooColors light = CubooColors(
    bg: Color(0xFFF4F1FF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE9E4FA),
    board: Color(0xFFD6CFF0),
    emptyCell: Color(0xFFEFEBFC),
    text: Color(0xFF1B1840),
    muted: Color(0xFF4A4678),
    bestText: Color(0xFF8A5A00),
    buttonShadow: Color(0xFFC94A3C),
    cardShadow: Color(0x1F1B1840),
  );

  static CubooColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? CubooColors.dark : CubooColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kCoral,
      brightness: brightness,
      surface: c.surface,
    ),
  );
}

/// 12480 becomes "12,480".
String formatScore(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
