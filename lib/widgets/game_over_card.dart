import 'package:flutter/material.dart';

import '../theme.dart';
import 'buttons.dart';

/// The "No moves left" card shown on top of the board.
class GameOverCard extends StatefulWidget {
  const GameOverCard({
    super.key,
    required this.score,
    required this.previousBest,
    required this.newBest,
    required this.onPlayAgain,
    required this.onHome,
    this.title = 'NO MOVES LEFT',
    this.onCopy,
  });

  final String title;

  /// When set, a "Copy" button copies the score text.
  final VoidCallback? onCopy;

  final int score;
  final int previousBest;
  final bool newBest;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  @override
  State<GameOverCard> createState() => _GameOverCardState();
}

class _GameOverCardState extends State<GameOverCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 700);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: c.cardShadow,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: c.muted,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SCORE',
              style: TextStyle(
                color: c.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: duration,
              curve: const Interval(0.35, 1, curve: Curves.easeOutBack),
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatScore(widget.score),
                  style: TextStyle(
                    color: c.text,
                    fontSize: 72,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (widget.newBest) ...[
              const SizedBox(height: 12),
              ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.07).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: kAmber,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Text(
                      'New best',
                      style: TextStyle(
                        color: kInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.newBest ? 'Previous best' : 'Best',
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        formatScore(widget.previousBest),
                        style: TextStyle(
                          color: c.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ChunkyButton(
              label: 'Play again',
              icon: Icons.refresh_rounded,
              height: 64,
              fontSize: 24,
              radius: 22,
              onPressed: widget.onPlayAgain,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    useAlt: true,
                    fontSize: 18,
                    onPressed: widget.onHome,
                  ),
                ),
                if (widget.onCopy != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftButton(
                      label: 'Copy',
                      icon: Icons.copy_rounded,
                      useAlt: true,
                      fontSize: 18,
                      onPressed: widget.onCopy,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
