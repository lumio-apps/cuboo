import 'package:shared_preferences/shared_preferences.dart';

/// Everything Cuboo saves lives on the phone, in SharedPreferences.
///
/// The keys below must never change between versions, otherwise an update
/// would lose the player's scores and settings.
class GameStorage {
  GameStorage(SharedPreferences prefs) : _prefs = prefs;

  /// Used when the phone storage cannot be opened (and in tests). Nothing is
  /// saved, but the game still works.
  GameStorage.inMemory() : _prefs = null;

  final SharedPreferences? _prefs;
  final Map<String, Object> _memory = {};

  static const String _kBest = 'cuboo.best';
  static const String _kTheme = 'cuboo.theme';
  static const String _kSound = 'cuboo.sound';
  static const String _kHaptics = 'cuboo.haptics';
  static const String _kGame = 'cuboo.game';

  T _get<T extends Object>(String key, T fallback) {
    try {
      final prefs = _prefs;
      final Object? value = prefs == null ? _memory[key] : prefs.get(key);
      if (value is T) return value;
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  // Saving is best effort: if the phone refuses, the game keeps running.
  Future<bool> _set(String key, Object value) async {
    final prefs = _prefs;
    if (prefs == null) {
      _memory[key] = value;
      return true;
    }
    try {
      if (value is int) return await prefs.setInt(key, value);
      if (value is bool) return await prefs.setBool(key, value);
      if (value is String) return await prefs.setString(key, value);
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _remove(String key) async {
    final prefs = _prefs;
    if (prefs == null) {
      _memory.remove(key);
      return true;
    }
    try {
      return await prefs.remove(key);
    } catch (_) {
      return false;
    }
  }

  int get best => _get<int>(_kBest, 0);
  Future<bool> setBest(int value) => _set(_kBest, value);

  /// "system", "light" or "dark".
  String get themeName => _get<String>(_kTheme, 'system');
  Future<bool> setThemeName(String value) => _set(_kTheme, value);

  bool get sound => _get<bool>(_kSound, true);
  Future<bool> setSound(bool value) => _set(_kSound, value);

  bool get haptics => _get<bool>(_kHaptics, true);
  Future<bool> setHaptics(bool value) => _set(_kHaptics, value);

  /// The running game as JSON text, or null when there is none.
  String? get savedGame {
    final value = _get<String>(_kGame, '');
    return value.isEmpty ? null : value;
  }

  Future<bool> saveGame(String json) => _set(_kGame, json);
  Future<bool> clearGame() => _remove(_kGame);
}
