import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../game/game.dart';
import '../game/shapes.dart';
import '../theme.dart';

/// Where the cells of the board are drawn, for a board of a given width.
class BoardGeometry {
  const BoardGeometry(this.side);

  final double side;

  static const double pad = 8;
  static const double gap = 3;

  double get cell => (side - pad * 2 - gap * (kBoardSize - 1)) / kBoardSize;
  double get pitch => cell + gap;

  Rect cellRect(int r, int c) =>
      Rect.fromLTWH(pad + c * pitch, pad + r * pitch, cell, cell);
}

Rect _scaled(Rect rect, double scale) => Rect.fromCenter(
      center: rect.center,
      width: rect.width * scale,
      height: rect.height * scale,
    );

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.t,
    required this.placed,
    required this.cleared,
    required this.ghost,
    required this.ghostColor,
    required this.hotRows,
    required this.hotCols,
    required this.boardColor,
    required this.emptyColor,
    required this.moveId,
  }) : style = BlockLook.style;

  final int moveId;
  final BlockStyle style;

  final List<List<int>> board;

  /// Animation progress of the last move, 0 to 1.
  final double t;
  final Set<int> placed;
  final List<ClearedCell> cleared;
  final List<Pos> ghost;
  final Color ghostColor;
  final Set<int> hotRows;
  final Set<int> hotCols;
  final Color boardColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(size.width);
    final radius = Radius.circular(g.cell * 0.28);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)),
      Paint()..color = boardColor,
    );

    final emptyPaint = Paint()..color = emptyColor;
    final hotPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.28);

    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final rect = g.cellRect(r, c);
        final v = board[r][c];
        if (v < 0) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), emptyPaint);
        } else {
          var drawRect = rect;
          if (placed.contains(r * kBoardSize + c)) {
            drawRect = _scaled(rect, 0.4 + 0.6 * Curves.easeOutBack.transform(t));
          }
          drawBlock(
            canvas,
            RRect.fromRectAndRadius(drawRect, radius),
            kBlockColors[v],
          );
        }
        if (hotRows.contains(r) || hotCols.contains(c)) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), hotPaint);
        }
      }
    }

    // Cells that were just cleared: they swell and fade out.
    if (cleared.isNotEmpty && t < 1) {
      for (final cell in cleared) {
        final rect = _scaled(g.cellRect(cell.row, cell.col), 1 + 0.25 * t);
        final color = Color.lerp(
          kBlockColors[cell.color],
          const Color(0xFFFFFFFF),
          0.55,
        )!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = color.withValues(alpha: 1 - Curves.easeIn.transform(t)),
        );
      }
    }

    // A few sparks flying out of every cleared cell.
    if (cleared.isNotEmpty && t < 1) {
      final spread = Curves.easeOut.transform(t);
      for (var i = 0; i < cleared.length; i++) {
        final cell = cleared[i];
        final center = g.cellRect(cell.row, cell.col).center;
        for (var k = 0; k < 3; k++) {
          final angle = i * 2.399 + k * 2.094;
          final distance = g.cell * (0.4 + 0.9 * spread);
          final spark = center +
              Offset(math.cos(angle) * distance, math.sin(angle) * distance);
          canvas.drawCircle(
            spark,
            g.cell * 0.13 * (1 - t),
            Paint()..color = kBlockColors[cell.color].withValues(alpha: 1 - t),
          );
        }
      }
    }

    // The preview of the piece being dragged.
    if (ghost.isNotEmpty) {
      final ghostPaint = Paint()..color = ghostColor.withValues(alpha: 0.6);
      for (final p in ghost) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(g.cellRect(p.r, p.c), radius),
          ghostPaint,
        );
      }
    }
  }

  static bool _samePositions(List<Pos> a, List<Pos> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // The board only changes together with moveId, so a repaint is needed only
  // when that, the animation, the preview or the colours change.
  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.moveId != moveId ||
      oldDelegate.style != style ||
      oldDelegate.boardColor != boardColor ||
      oldDelegate.emptyColor != emptyColor ||
      oldDelegate.ghostColor != ghostColor ||
      !_samePositions(oldDelegate.ghost, ghost) ||
      !setEquals(oldDelegate.hotRows, hotRows) ||
      !setEquals(oldDelegate.hotCols, hotCols);
}

/// Draws the board. Restarts its small animation whenever [moveId] changes.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.side,
    required this.moveId,
    this.placed = const [],
    this.cleared = const [],
    this.ghost = const [],
    this.ghostColor = kCoral,
    this.hotRows = const {},
    this.hotCols = const {},
  });

  final List<List<int>> board;
  final double side;
  final int moveId;
  final List<Pos> placed;
  final List<ClearedCell> cleared;
  final List<Pos> ghost;
  final Color ghostColor;
  final Set<int> hotRows;
  final Set<int> hotCols;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final placedSet = <int>{for (final p in placed) p.r * kBoardSize + p.c};
    return RepaintBoundary(
      child: Semantics(
      label: 'Game board',
      child: SizedBox(
        width: side,
        height: side,
        child: TweenAnimationBuilder<double>(
          key: ValueKey<int>(moveId),
          tween: Tween<double>(begin: 0, end: 1),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 420),
          builder: (context, t, _) => CustomPaint(
            painter: _BoardPainter(
              board: board,
              t: t,
              placed: placedSet,
              cleared: cleared,
              ghost: ghost,
              ghostColor: ghostColor,
              hotRows: hotRows,
              hotCols: hotCols,
              boardColor: c.board,
              emptyColor: c.emptyCell,
              moveId: moveId,
            ),
          ),
        ),
      ),
      ),
    );
  }
}
