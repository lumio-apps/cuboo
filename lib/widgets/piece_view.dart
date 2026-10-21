import 'package:flutter/material.dart';

import '../game/shapes.dart';

class _PiecePainter extends CustomPainter {
  _PiecePainter(this.shape, this.color, this.cell, this.gap);

  final Shape shape;
  final Color color;
  final double cell;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = Radius.circular(cell * 0.28);
    for (final p in shape.cells) {
      final rect = Rect.fromLTWH(
        p.c * (cell + gap),
        p.r * (cell + gap),
        cell,
        cell,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.cell != cell ||
      oldDelegate.gap != gap;
}

/// Size in pixels of [shape] drawn with the given cell size and gap.
Size pieceSize(Shape shape, double cell, double gap) => Size(
      shape.width * cell + (shape.width - 1) * gap,
      shape.height * cell + (shape.height - 1) * gap,
    );

/// A block piece, as shown in the tray or while it is being dragged.
class PieceView extends StatelessWidget {
  const PieceView({
    super.key,
    required this.shape,
    required this.color,
    required this.cell,
    this.gap = 3,
  });

  final Shape shape;
  final Color color;
  final double cell;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: pieceSize(shape, cell, gap),
      painter: _PiecePainter(shape, color, cell, gap),
    );
  }
}
