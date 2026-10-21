import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'stats.dart';
import 'storage.dart';
import 'theme.dart';

/// Settings and the best score. Screens listen to this and rebuild.
class AppState extends ChangeNotifier {
  AppState(this.storage)
      : _themeMode = _parseTheme(storage.themeName),
        _sound = storage.sound,
        _haptics = storage.haptics,
        _best = storage.best,
        _paletteIndex = _clampIndex(storage.palette, kPalettes.length),
        _blockStyle = BlockStyle.values[
            _clampIndex(storage.blockStyle, BlockStyle.values.length)],
        _leftHanded = storage.leftHanded,
        _stats = Stats.parse(storage.statsJson),
        _history = _parseHistory(storage.historyRaw),
        _unlocked = _parseIds(storage.achievementsRaw) {
    BlockLook.paletteIndex = _paletteIndex;
    BlockLook.style = _blockStyle;
  }

  final GameStorage storage;

  ThemeMode _themeMode;
  bool _sound;
  bool _haptics;
  int _best;
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

  /// Remembers [score] if it beats the best one.
  void submitScore(int score) {
    if (score <= _best) return;
    _best = score;
    storage.setBest(score);
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

  void placeFeedback() {
    if (_haptics) HapticFeedback.lightImpact();
    if (_sound) SystemSound.play(SystemSoundType.click);
  }

  void clearFeedback() {
    if (_haptics) HapticFeedback.mediumImpact();
    if (_sound) SystemSound.play(SystemSoundType.click);
  }

  void overFeedback() {
    if (_haptics) HapticFeedback.heavyImpact();
  }
}
