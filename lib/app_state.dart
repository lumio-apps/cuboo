import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'storage.dart';

/// Settings and the best score. Screens listen to this and rebuild.
class AppState extends ChangeNotifier {
  AppState(this.storage)
      : _themeMode = _parseTheme(storage.themeName),
        _sound = storage.sound,
        _haptics = storage.haptics,
        _best = storage.best;

  final GameStorage storage;

  ThemeMode _themeMode;
  bool _sound;
  bool _haptics;
  int _best;

  ThemeMode get themeMode => _themeMode;
  bool get sound => _sound;
  bool get haptics => _haptics;
  int get best => _best;

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
