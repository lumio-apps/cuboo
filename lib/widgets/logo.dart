import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

// The logo is a letter "C" built from blocks, with a dashed empty slot.
// (column, row, colour index into kBlockColors)
const List<List<int>> _logoCells = [
  [0, 0, 0],
  [1, 0, 1],
  [2, 0, 1],
  [0, 1, 2],
  [0, 2, 3],
  [1, 2, 4],
  [2, 2, 4],
];

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.progress);

  /// 0 = nothing visible yet, 1 = fully drawn.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.2187),
    );
    canvas.drawRRect(bg, Paint()..color = const Color(0xFF1B1840));

    final total = s * 0.64;
    final gap = total * 0.0427;
    final cell = (total - 2 * gap) / 3;
    final off = (s - total) / 2;
    final radius = Radius.circular(cell * 0.22);

    for (var i = 0; i < _logoCells.length; i++) {
      final spec = _logoCells[i];
      final x = off + spec[0] * (cell + gap);
      final y = off + spec[1] * (cell + gap);
      final t = ((progress * 1.6 - i * 0.12) / 0.6).clamp(0.0, 1.0).toDouble();
      final scale = Curves.easeOutBack.transform(t);
      if (scale <= 0) continue;
      final rect = Rect.fromCenter(
        center: Offset(x + cell / 2, y + cell / 2),
        width: cell * scale,
        height: cell * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = kBlockColors[spec[2]],
      );
    }

    // The dashed empty slot at column 2, row 1.
    final slotT = ((progress * 1.6 - 0.9) / 0.6).clamp(0.0, 1.0).toDouble();
    if (slotT > 0) {
      final x = off + 2 * (cell + gap);
      final y = off + 1 * (cell + gap);
      final inset = cell * 0.02;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + inset, y + inset, cell - 2 * inset, cell - 2 * inset),
        radius,
      );
      final paint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4 * slotT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, cell * 0.05);
      final path = Path()..addRRect(rrect);
      final dash = cell * 0.12;
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final end = math.min(distance + dash, metric.length);
          canvas.drawPath(metric.extractPath(distance, end), paint);
          distance += dash * 2;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// The Cuboo logo. With [animate] the blocks pop in one by one and the whole
/// logo floats gently. Both stop when the phone asks to reduce motion.
class CubooLogo extends StatefulWidget {
  const CubooLogo({super.key, this.size = 148, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<CubooLogo> createState() => _CubooLogoState();
}

class _CubooLogoState extends State<CubooLogo> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!widget.animate || reduce) {
      _intro.value = 1;
    } else {
      _intro.forward();
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cuboo logo',
      image: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_intro, _float]),
        builder: (context, child) {
          final lift = -8 * Curves.easeInOut.transform(_float.value);
          return Transform.translate(
            offset: Offset(0, lift),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _LogoPainter(_intro.value),
            ),
          );
        },
      ),
    );
  }
}
