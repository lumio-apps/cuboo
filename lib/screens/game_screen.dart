import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../game/game.dart';
import '../game/mode.dart';
import '../game/shapes.dart';
import '../stats.dart';
import '../update_service.dart';
import '../theme.dart';
import '../widgets/board_view.dart';
import '../widgets/buttons.dart';
import '../widgets/game_over_card.dart';
import '../widgets/piece_view.dart';
import '../widgets/scaffold.dart';

class _Target {
  const _Target(this.r, this.c);

  final int r;
  final int c;
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.app,
    this.mode,
    this.startNew = false,
  });

  final AppState app;

  /// The mode to start. When null, the saved game (and its mode) continues.
  final GameMode? mode;

  /// When true a fresh game starts even if one was saved.
  final bool startNew;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  /// How far above the finger the dragged piece floats, so it stays visible.
  static const double _lift = 56;
  static const double _trayHeight = 104;

  late CubooGame _game;
  late GameMode _mode;

  int _timeLeft = kTimedSeconds;
  int _hintsLeft = 3;
  Hint? _hint;
  Timer? _hintTimer;
  Timer? _ticker;
  bool _paused = false;
  int _shakeId = 0;

  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _bobStarted = false;

  int _moveId = 0;
  List<Pos> _placed = const [];
  List<ClearedCell> _cleared = const [];
  int _gainId = 0;
  int _lastGain = 0;

  int? _dragIndex;
  int _dragPointer = -1;
  Offset _dragPos = Offset.zero;
  Offset _dragStart = Offset.zero;
  double _side = 320;

  bool _showOver = false;
  bool _newBest = false;
  int _previousBest = 0;
  Timer? _overTimer;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode ?? GameMode.classic;
    _game = _loadGame();
    _startTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bobStarted) return;
    _bobStarted = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _overTimer?.cancel();
    _hintTimer?.cancel();
    _ticker?.cancel();
    _bob.dispose();
    super.dispose();
  }

  CubooGame _newGame() {
    _timeLeft = kTimedSeconds;
    _hintsLeft = 3;
    if (_mode == GameMode.daily) {
      return CubooGame(random: math.Random(dailySeed(DateTime.now())));
    }
    return CubooGame();
  }

  CubooGame _loadGame() {
    CubooGame? restored;
    if (!widget.startNew) {
      final raw = widget.app.storage.savedGame;
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final game = CubooGame.fromJson(map);
          if (!game.over) {
            restored = game;
            if (widget.mode == null) {
              _mode = GameModeInfo.parse(map['mode']);
            }
            final time = map['time'];
            if (time is int && time > 0 && time <= kTimedSeconds) {
              _timeLeft = time;
            }
            final hints = map['hints'];
            if (hints is int && hints >= 0 && hints <= 3) _hintsLeft = hints;
          }
        } catch (_) {
          restored = null;
        }
      }
    }
    if (restored != null) return restored;
    widget.app.storage.clearGame();
    return _newGame();
  }

  void _save() {
    if (_game.over) return;
    widget.app.storage.saveGame(
      jsonEncode({
        ..._game.toJson(),
        'mode': _mode.name,
        'time': _timeLeft,
        'hints': _hintsLeft,
      }),
    );
  }

  // ---- Timer and hints ----------------------------------------------------

  void _startTicker() {
    _ticker?.cancel();
    if (_mode != GameMode.timed) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused || _showOver || _game.over) return;
      if (_timeLeft <= 1) {
        setState(() {
          _timeLeft = 0;
          _dragIndex = null;
          _game.over = true;
        });
        _finish();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _showHint() {
    if (_hintsLeft <= 0 || _game.over || _showOver || _dragIndex != null) {
      return;
    }
    final hint = _game.findHint();
    if (hint == null) return;
    widget.app.tapFeedback();
    _hintTimer?.cancel();
    setState(() {
      _hintsLeft--;
      _hint = hint;
    });
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hint = null);
    });
    _save();
  }

  void _clearHint() {
    _hintTimer?.cancel();
    _hint = null;
  }

  // ---- Dragging -----------------------------------------------------------

  Offset? _globalOrigin(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero);
    }
    return null;
  }

  Offset _pieceTopLeft(Shape shape, BoardGeometry g) {
    final size = pieceSize(shape, g.cell, BoardGeometry.gap);
    return Offset(
      _dragPos.dx - size.width / 2,
      _dragPos.dy - size.height - _lift,
    );
  }

  _Target? _target() {
    final index = _dragIndex;
    if (index == null) return null;
    final piece = _game.tray[index];
    if (piece == null) return null;
    final origin = _globalOrigin(_boardKey);
    if (origin == null) return null;
    final g = BoardGeometry(_side);
    final topLeft = _pieceTopLeft(piece.shape, g);
    final c = ((topLeft.dx - origin.dx - BoardGeometry.pad) / g.pitch).round();
    final r = ((topLeft.dy - origin.dy - BoardGeometry.pad) / g.pitch).round();
    return _Target(r, c);
  }

  void _startDrag(int index, int pointer, Offset global) {
    if (_dragIndex != null) return; // one finger at a time
    if (_game.over || _showOver || _game.tray[index] == null) return;
    widget.app.tapFeedback();
    _clearHint();
    setState(() {
      _dragIndex = index;
      _dragPointer = pointer;
      _dragPos = global;
      _dragStart = global;
    });
  }

  void _updateDrag(int pointer, Offset global) {
    if (_dragIndex == null || pointer != _dragPointer) return;
    setState(() => _dragPos = global);
  }

  void _endDrag(int pointer) {
    final index = _dragIndex;
    if (index == null || pointer != _dragPointer) return;
    final target = _target();
    final tapped = (_dragPos - _dragStart).distance < 12;
    setState(() => _dragIndex = null);
    if (tapped && _mode == GameMode.relaxed) {
      // A tap (no drag) turns the piece in Relaxed mode.
      if (_game.rotate(index)) {
        widget.app.tapFeedback();
        setState(() {});
        _save();
      }
      return;
    }
    if (target != null && _game.canPlace(index, target.r, target.c)) {
      _place(index, target.r, target.c);
    }
  }

  void _cancelDrag(int pointer) {
    if (_dragIndex != null && pointer == _dragPointer) {
      setState(() => _dragIndex = null);
    }
  }

  // ---- Moves --------------------------------------------------------------

  void _place(int index, int r, int c) {
    final result = _game.place(index, r, c);
    if (result == null) return;
    setState(() {
      _moveId++;
      _placed = result.placed;
      _cleared = result.cleared;
      _gainId++;
      _lastGain = result.gained;
      _clearHint();
      if (result.placed.isEmpty || result.lines >= 3 || result.combo >= 4) {
        _shakeId++;
      }
    });
    if (result.placed.isEmpty) {
      widget.app.bombFeedback();
    } else if (result.lines > 0) {
      widget.app.clearFeedback(combo: result.combo);
    } else {
      widget.app.placeFeedback();
    }
    _announce(widget.app.recordMove(
      lines: result.lines,
      combo: result.combo,
      score: _game.score,
    ));
    if (_mode == GameMode.relaxed) {
      widget.app.submitScore(_game.score, mode: _mode);
      if (_game.over) {
        _game.clearBoard();
        setState(() {
          _moveId++;
          _placed = const [];
          _cleared = const [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No moves left. The board was cleared!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (_game.over) {
      _finish();
    } else {
      _save();
    }
  }

  void _finish() {
    final app = widget.app;
    _previousBest = app.bestFor(_mode);
    _newBest = _game.score > _previousBest;
    app.submitScore(_game.score, mode: _mode);
    _announce(app.recordGameOver(_game.score));
    app.storage.clearGame();
    app.overFeedback();
    _overTimer?.cancel();
    _overTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showOver = true);
    });
  }

  void _announce(List<Achievement> unlocked) {
    if (unlocked.isEmpty || !mounted) return;
    final names = unlocked.map((a) => a.title).join(', ');
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Achievement unlocked: $names'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _undo() {
    if (!_game.undo()) return;
    widget.app.tapFeedback();
    _clearHint();
    setState(() {
      _moveId++;
      _placed = const [];
      _cleared = const [];
    });
    _save();
  }

  void _restart() {
    _overTimer?.cancel();
    widget.app.storage.clearGame();
    _clearHint();
    setState(() {
      _game = _newGame();
      _moveId++;
      _placed = const [];
      _cleared = const [];
      _gainId = 0;
      _lastGain = 0;
      _dragIndex = null;
      _showOver = false;
      _newBest = false;
    });
    _startTicker();
    _save();
  }

  void _copyScore() {
    final text = 'I scored ${formatScore(_game.score)} in Cuboo '
        '(${_mode.title})! github.com/$kGithubOwner/$kGithubRepo';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Score copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pause() async {
    if (_showOver) return;
    _paused = true;
    final c = CubooColors.of(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          'Paused',
          style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('home'),
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('restart'),
            child: const Text('Restart'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('resume'),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    _paused = false;
    if (!mounted) return;
    if (choice == 'home') {
      _save();
      Navigator.of(context).pop();
    } else if (choice == 'restart') {
      _restart();
    }
  }

  // ---- Building -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return PopScope(
      canPop: _showOver,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _pause();
      },
      child: CubooScaffold(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const fixed = 60.0 + 36.0 + _trayHeight + 52.0 + 16.0 * 5;
            final maxSide = constraints.maxHeight - fixed;
            _side = math
                .min(constraints.maxWidth - 32, maxSide)
                .clamp(180.0, 480.0)
                .toDouble();
            return Stack(
              key: _stackKey,
              children: [
                Positioned.fill(child: _content(c)),
                if (_dragIndex != null) _floating(),
                if (_showOver)
                  Positioned.fill(
                    child: ColoredBox(
                      color: c.bg.withValues(alpha: 0.9),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GameOverCard(
                            title: _mode == GameMode.timed
                                ? "TIME'S UP"
                                : 'NO MOVES LEFT',
                            onCopy: _copyScore,
                            score: _game.score,
                            previousBest: _previousBest,
                            newBest: _newBest,
                            onPlayAgain: _restart,
                            onHome: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(CubooColors c) {
    return Center(
      child: SizedBox(
        width: _side,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _header(c),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_mode == GameMode.timed) ...[
                  _timerPill(c),
                  const SizedBox(width: 10),
                ],
                _comboChip(),
              ],
            ),
            const SizedBox(height: 16),
            _boardArea(c),
            const Spacer(),
            _tray(c),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: _game.undosLeft > 0
                        ? 'Undo (${_game.undosLeft} left)'
                        : 'Undo used',
                    icon: Icons.undo_rounded,
                    height: 52,
                    fontSize: 15,
                    onPressed: _game.canUndo ? _undo : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SoftButton(
                    label: 'Hint ($_hintsLeft)',
                    icon: Icons.lightbulb_outline_rounded,
                    height: 52,
                    fontSize: 15,
                    onPressed: _hintsLeft > 0 && !_game.over ? _showHint : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _header(CubooColors c) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final best = math.max(widget.app.bestFor(_mode), _game.score);
    final left = widget.app.leftHanded;
    return SizedBox(
      height: 60,
      child: Row(
        textDirection: left ? TextDirection.rtl : TextDirection.ltr,
        children: [
          SizedBox(
            width: 96,
            child: Align(
              alignment: left ? Alignment.centerRight : Alignment.centerLeft,
              child: IconSquareButton(
                icon: Icons.pause_rounded,
                tooltip: 'Pause',
                onPressed: _pause,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SCORE',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                TweenAnimationBuilder<int>(
                  tween: IntTween(end: _game.score),
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  builder: (context, value, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatScore(value),
                      style: TextStyle(
                        color: c.text,
                        fontSize: 36,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  'BEST',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: left ? Alignment.centerLeft : Alignment.centerRight,
                  child: Text(
                    formatScore(best),
                    style: TextStyle(
                      color: c.bestText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerPill(CubooColors c) {
    final minutes = _timeLeft ~/ 60;
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    final urgent = _timeLeft <= 10;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: urgent ? kCoral : c.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            widthFactor: 1,
            child: Text(
              '$minutes:$seconds',
              style: TextStyle(
                color: urgent ? kInk : c.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _comboChip() {
    if (_game.combo < 2) return const SizedBox(height: 36);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 36,
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(_moveId),
        tween: Tween<double>(begin: 0, end: 1),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
        builder: (context, t, child) => Transform.scale(
          scale: 1 + 0.22 * math.sin(math.pi * t),
          child: child,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: kAmber,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              widthFactor: 1,
              child: Text(
                'Combo x${_game.combo}',
                style: const TextStyle(
                  color: kInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boardArea(CubooColors c) {
    var ghost = const <Pos>[];
    var hotRows = const <int>{};
    var hotCols = const <int>{};
    var ghostColor = kCoral;
    final index = _dragIndex;
    final target = _target();
    final hint = _hint;
    if (index == null && hint != null && _game.tray[hint.index] != null) {
      final preview = _game.preview(hint.index, hint.r, hint.c);
      if (preview != null) {
        ghost = preview.blast.isNotEmpty ? preview.blast : preview.cells;
        hotRows = preview.rows;
        hotCols = preview.cols;
        ghostColor = _game.tray[hint.index]!.bomb
            ? kCoral
            : kBlockColors[_game.tray[hint.index]!.color];
      }
    }
    if (index != null && target != null) {
      final preview = _game.preview(index, target.r, target.c);
      if (preview != null) {
        ghost = preview.blast.isNotEmpty ? preview.blast : preview.cells;
        hotRows = preview.rows;
        hotCols = preview.cols;
        ghostColor = _game.tray[index]!.bomb
            ? kCoral
            : kBlockColors[_game.tray[index]!.color];
      }
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: _side,
      height: _side,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _shakeId.toDouble()),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 380),
        builder: (context, t, child) {
          final f = t - t.floorToDouble();
          return Transform.translate(
            offset: Offset(math.sin(f * math.pi * 8) * 5 * (1 - f), 0),
            child: child,
          );
        },
        child: Stack(
        clipBehavior: Clip.none,
        children: [
          KeyedSubtree(
            key: _boardKey,
            child: BoardView(
              board: _game.board,
              side: _side,
              moveId: _moveId,
              placed: _placed,
              cleared: _cleared,
              ghost: ghost,
              ghostColor: ghostColor,
              hotRows: hotRows,
              hotCols: hotCols,
            ),
          ),
          if (_gainId > 0) _gainPopup(),
        ],
      ),
      ),
    );
  }

  Widget _gainPopup() {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey<int>(_gainId),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          builder: (context, t, _) => Opacity(
            opacity: 1 - t * t,
            child: Align(
              alignment: Alignment(0, -0.1 - 0.5 * t),
              child: Text(
                '+$_lastGain',
                style: const TextStyle(
                  color: kAmber,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Color(0x88000000), blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tray(CubooColors c) {
    final slotWidth = (_side - 24) / kTraySize;
    final order = [
      for (var i = 0; i < kTraySize; i++) i,
    ];
    if (widget.app.leftHanded) order.setAll(0, order.reversed.toList());
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, _) => Row(
        children: [
          for (var n = 0; n < kTraySize; n++) ...[
            if (n > 0) const SizedBox(width: 12),
            SizedBox(
              width: slotWidth,
              height: _trayHeight,
              child: _slot(order[n], c, slotWidth),
            ),
          ],
        ],
      ),
    );
  }

  Widget _slot(int i, CubooColors c, double slotWidth) {
    final decoration = BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
    );
    final piece = _game.tray[i];
    if (piece == null) return DecoratedBox(decoration: decoration);

    final shape = piece.shape;
    final byWidth = (slotWidth - 24 - (shape.width - 1) * 3) / shape.width;
    final byHeight =
        (_trayHeight - 24 - (shape.height - 1) * 3) / shape.height;
    final cell = math.min(22.0, math.min(byWidth, byHeight));
    final dragging = _dragIndex == i;
    final dy = math.sin(_bob.value * 2 * math.pi + i * 1.3) * 4;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _startDrag(i, event.pointer, event.position),
      onPointerMove: (event) => _updateDrag(event.pointer, event.position),
      onPointerUp: (event) => _endDrag(event.pointer),
      onPointerCancel: (event) => _cancelDrag(event.pointer),
      child: Semantics(
        label: 'Piece ${i + 1}. Drag it onto the board.',
        child: DecoratedBox(
          decoration: decoration,
          child: Center(
            child: Opacity(
              opacity: dragging ? 0.25 : 1,
              child: Transform.translate(
                offset: Offset(0, dy),
                child: PieceView(
                  shape: shape,
                  color: kBlockColors[piece.color],
                  cell: cell,
                  bomb: piece.bomb,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _floating() {
    final index = _dragIndex;
    final piece = index == null ? null : _game.tray[index];
    if (piece == null) return const SizedBox.shrink();
    final stackOrigin = _globalOrigin(_stackKey) ?? Offset.zero;
    final g = BoardGeometry(_side);
    final topLeft = _pieceTopLeft(piece.shape, g) - stackOrigin;
    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      child: IgnorePointer(
        child: PieceView(
          shape: piece.shape,
          color: kBlockColors[piece.color],
          cell: g.cell,
          bomb: piece.bomb,
        ),
      ),
    );
  }
}
