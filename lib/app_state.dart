import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/mode.dart';
import 'sound.dart';
import 'stats.dart';
import 'storage.dart';
import 'theme.dart';

/// Settings and the best score. Screens listen to this and rebuild.
class AppState extends ChangeNotifier {
  AppState(this.storage)
      : _themeMode = _parseTheme(storage.themeName),
        _sound = storage.sound,
        _haptics = storage.haptics,
        launches = storage.launches + 1,
        _best = storage.best,
        _bestRelaxed = storage.bestRelaxed,
        _bestTimed = storage.bestTimed,
        _daily = _parseDaily(storage.dailyRaw),
        _paletteIndex = _clampIndex(storage.palette, kPalettes.length),
        _blockStyle = BlockStyle.values[
            _clampIndex(storage.blockStyle, BlockStyle.values.length)],
        _leftHanded = storage.leftHanded,
        _stats = Stats.parse(storage.statsJson),
        _history = _parseHistory(storage.historyRaw),
        _unlocked = _parseIds(storage.achievementsRaw) {
    BlockLook.paletteIndex = _paletteIndex;
    BlockLook.style = _blockStyle;
    storage.setLaunches(launches);
  }

  final GameStorage storage;

  /// How many times the app has been opened, including this time.
  final int launches;
  final SoundPlayer _player = SoundPlayer();

  ThemeMode _themeMode;
  bool _sound;
  bool _haptics;
  int _best;
  int _bestRelaxed;
  int _bestTimed;
  ({int seed, int score}) _daily;

  static ({int seed, int score}) _parseDaily(String raw) {
    final parts = raw.split(':');
    if (parts.length == 2) {
      final seed = int.tryParse(parts[0]);
      final score = int.tryParse(parts[1]);
      if (seed != null && score != null && score >= 0) {
        return (seed: seed, score: score);
      }
    }
    return (seed: 0, score: 0);
  }
  int _paletteIndex;
  BlockStyle _blockStyle;
  bool _leftHanded;
  Stats _stats;
  List<int> _history;
  Set<String> _unlocked;

  static const int kHistoryLength = 10;

  static int _clampIndex(int value, int length) =>
      value >= 0 && value < length ? value : 0;

  static List<int> _parseHistory(String raw) {
    final out = <int>[];
    for (final part in raw.split(',')) {
      final value = int.tryParse(part);
      if (value != null && value >= 0) out.add(value);
    }
    return out.take(kHistoryLength).toList();
  }

  static Set<String> _parseIds(String raw) =>
      {for (final part in raw.split(',')) if (part.isNotEmpty) part};

  ThemeMode get themeMode => _themeMode;
  bool get sound => _sound;
  bool get haptics => _haptics;
  int get best => _best;
  int get paletteIndex => _paletteIndex;
  BlockStyle get blockStyle => _blockStyle;
  bool get leftHanded => _leftHanded;
  Stats get stats => _stats;

  /// Recent scores, newest first.
  List<int> get history => List.unmodifiable(_history);
  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  static ThemeMode _parseTheme(String name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    storage.setThemeName(mode.name);
    notifyListeners();
  }

  void setSound(bool value) {
    _sound = value;
    storage.setSound(value);
    notifyListeners();
  }

  void setHaptics(bool value) {
    _haptics = value;
    storage.setHaptics(value);
    notifyListeners();
  }

  /// The best score of [mode]. For the Daily Challenge it is today's best.
  int bestFor(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return _best;
      case GameMode.relaxed:
        return _bestRelaxed;
      case GameMode.timed:
        return _bestTimed;
      case GameMode.daily:
        return _daily.seed == dailySeed(DateTime.now()) ? _daily.score : 0;
    }
  }

  /// Remembers [score] if it beats the best one of [mode].
  void submitScore(int score, {GameMode mode = GameMode.classic}) {
    if (score <= bestFor(mode)) return;
    switch (mode) {
      case GameMode.classic:
        _best = score;
        storage.setBest(score);
      case GameMode.relaxed:
        _bestRelaxed = score;
        storage.setBestRelaxed(score);
      case GameMode.timed:
        _bestTimed = score;
        storage.setBestTimed(score);
      case GameMode.daily:
        final seed = dailySeed(DateTime.now());
        _daily = (seed: seed, score: score);
        storage.saveDaily('$seed:$score');
    }
    notifyListeners();
  }

  void setPalette(int index) {
    if (index < 0 || index >= kPalettes.length || index == _paletteIndex) {
      return;
    }
    _paletteIndex = index;
    BlockLook.paletteIndex = index;
    storage.setPalette(index);
    notifyListeners();
  }

  void setBlockStyle(BlockStyle style) {
    if (style == _blockStyle) return;
    _blockStyle = style;
    BlockLook.style = style;
    storage.setBlockStyle(style.index);
    notifyListeners();
  }

  void setLeftHanded(bool value) {
    _leftHanded = value;
    storage.setLeftHanded(value);
    notifyListeners();
  }

  /// Call after every move. Returns achievements unlocked by it.
  List<Achievement> recordMove({
    required int lines,
    required int combo,
    required int score,
  }) {
    _stats = _stats.copyWith(
      totalLines: _stats.totalLines + lines,
      bestCombo: combo > _stats.bestCombo ? combo : _stats.bestCombo,
      bestMoveLines: lines > _stats.bestMoveLines ? lines : _stats.bestMoveLines,
    );
    storage.saveStats(_stats.toJsonString());
    return _unlockNew(score);
  }

  /// Call once when a game ends. Returns achievements unlocked by it.
  List<Achievement> recordGameOver(int score) {
    _stats = _stats.copyWith(
      games: _stats.games + 1,
      totalScore: _stats.totalScore + score,
    );
    storage.saveStats(_stats.toJsonString());
    _history = [score, ..._history].take(kHistoryLength).toList();
    storage.saveHistory(_history.join(','));
    final fresh = _unlockNew(score);
    notifyListeners();
    return fresh;
  }

  List<Achievement> _unlockNew(int score) {
    final bestScore = score > _best ? score : _best;
    final fresh = <Achievement>[
      for (final a in kAchievements)
        if (!_unlocked.contains(a.id) && isEarned(a.id, _stats, bestScore)) a,
    ];
    if (fresh.isNotEmpty) {
      _unlocked = {..._unlocked, for (final a in fresh) a.id};
      storage.saveAchievements(_unlocked.join(','));
    }
    return fresh;
  }

  // Small feedback helpers, so every screen behaves the same.

  void tapFeedback() {
    if (_haptics) HapticFeedback.selectionClick();
  }

  /// Loads the sounds in advance so the first one does not stutter.
  Future<void> warmUpSound() => _player.warmUp();

  void _sfx(String name) {
    if (_sound) unawaited(_player.play(name));
  }

  void placeFeedback() {
    if (_haptics) HapticFeedback.lightImpact();
    _sfx('place');
  }

  void clearFeedback({int combo = 1}) {
    if (_haptics) HapticFeedback.mediumImpact();
    _sfx(combo >= 2 ? 'combo' : 'clear');
  }

  void bombFeedback() {
    if (_haptics) HapticFeedback.heavyImpact();
    _sfx('bomb');
  }

  void overFeedback() {
    if (_haptics) HapticFeedback.heavyImpact();
    _sfx('over');
  }
}
