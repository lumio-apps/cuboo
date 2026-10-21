import 'package:flutter/material.dart';

/// The classic block colours. The logo always uses these.
const List<Color> kClassicColors = [
  Color(0xFFFF6B5B), // coral
  Color(0xFFFFC24D), // amber
  Color(0xFF2EC4B6), // teal
  Color(0xFF4DA3FF), // sky
  Color(0xFF8B7CFF), // violet
];

/// A named set of five block colours.
class BlockPalette {
  const BlockPalette(this.name, this.colors);

  final String name;
  final List<Color> colors;
}

const List<BlockPalette> kPalettes = [
  BlockPalette('Classic', kClassicColors),
  BlockPalette('Candy', [
    Color(0xFFFF7EB6),
    Color(0xFFFFD866),
    Color(0xFF7BE0AD),
    Color(0xFF7AB8FF),
    Color(0xFFC39BFF),
  ]),
  BlockPalette('Ocean', [
    Color(0xFF0077B6),
    Color(0xFF00B4D8),
    Color(0xFF2EC4B6),
    Color(0xFF5E60CE),
    Color(0xFF48CAE4),
  ]),
  BlockPalette('Forest', [
    Color(0xFF2D6A4F),
    Color(0xFF52B788),
    Color(0xFFE9C46A),
    Color(0xFFBC6C25),
    Color(0xFF95D5B2),
  ]),
  BlockPalette('Mono', [
    Color(0xFF2B3454),
    Color(0xFF3F4A6B),
    Color(0xFF5C6784),
    Color(0xFF7B88A8),
    Color(0xFF9AA5C4),
  ]),
];

/// How a single block is drawn.
enum BlockStyle { flat, glossy, outlined }

/// The block look that is currently selected (set by AppState).
class BlockLook {
  BlockLook._();

  static int paletteIndex = 0;
  static BlockStyle style = BlockStyle.flat;
}

/// The block colours of the selected palette.
List<Color> get kBlockColors => kPalettes[BlockLook.paletteIndex].colors;

/// Draws one block in the selected [BlockStyle].
void drawBlock(Canvas canvas, RRect rrect, Color color) {
  switch (BlockLook.style) {
    case BlockStyle.flat:
      canvas.drawRRect(rrect, Paint()..color = color);
    case BlockStyle.glossy:
      canvas.drawRRect(rrect, Paint()..color = color);
      final r = rrect.outerRect;
      final shine = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          r.left + r.width * 0.14,
          r.top + r.height * 0.1,
          r.width * 0.72,
          r.height * 0.3,
        ),
        Radius.circular(r.height * 0.15),
      );
      canvas.drawRRect(
        shine,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3),
      );
    case BlockStyle.outlined:
      canvas.drawRRect(
        rrect,
        Paint()..color = color.withValues(alpha: 0.3),
      );
      final width = rrect.outerRect.width * 0.12;
      canvas.drawRRect(
        rrect.deflate(width / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
  }
}

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
