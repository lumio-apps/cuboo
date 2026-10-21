import 'package:flutter/material.dart';

import '../game/shapes.dart';
import '../theme.dart';

class _PiecePainter extends CustomPainter {
  _PiecePainter(this.shape, this.color, this.cell, this.gap, this.bomb)
      : style = BlockLook.style;

  final bool bomb;

  final BlockStyle style;
  final Shape shape;
  final Color color;
  final double cell;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(cell * 0.28);
    for (final p in shape.cells) {
      final rect = Rect.fromLTWH(
        p.c * (cell + gap),
        p.r * (cell + gap),
        cell,
        cell,
      );
      final rrect = RRect.fromRectAndRadius(rect, radius);
      if (bomb) {
        canvas.drawRRect(rrect, Paint()..color = const Color(0xFF2A2740));
        canvas.drawRRect(
          rrect.deflate(cell * 0.05),
          Paint()
            ..color = kCoral
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.1,
        );
        canvas.drawCircle(rect.center, cell * 0.17, Paint()..color = kAmber);
      } else {
        drawBlock(canvas, rrect, color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.style != style ||
      oldDelegate.bomb != bomb ||
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
    this.bomb = false,
  });

  final Shape shape;
  final Color color;
  final double cell;
  final double gap;
  final bool bomb;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: pieceSize(shape, cell, gap),
      painter: _PiecePainter(shape, color, cell, gap, bomb),
    );
  }
}
