import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Everything Cuboo saves lives on the phone. Normally that is
/// SharedPreferences. If the phone refuses to open it, a small JSON file in
/// the app's private folder is used instead (see [openFile]).
///
/// The keys below must never change between versions, otherwise an update
/// would lose the player's scores and settings.
class GameStorage {
  GameStorage(SharedPreferences prefs)
      : _prefs = prefs,
        _file = null,
        problem = null,
        saveFailed = false;

  /// Nothing is saved, but the game works. Used in tests.
  GameStorage.inMemory()
      : _prefs = null,
        _file = null,
        problem = null,
        saveFailed = false;

  /// Like [inMemory], but for when no storage could be opened at all. The
  /// home screen tells the player that nothing will be kept.
  GameStorage.unavailable({this.problem})
      : _prefs = null,
        _file = null,
        saveFailed = true;

  GameStorage._withFile(File file, Map<String, Object> data, this.problem)
      : _prefs = null,
        _file = file,
        saveFailed = false {
    _memory.addAll(data);
  }

  /// Saves into a JSON [file] (created when missing). A broken or unreadable
  /// file just means empty data. [problem] says why SharedPreferences was not
  /// used, so Settings can show it.
  static Future<GameStorage> openFile(File file, {String? problem}) async {
    final data = <String, Object>{};
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is int || value is bool || value is String) {
              data[entry.key] = value as Object;
            }
          }
        }
      }
    } catch (_) {
      // Unreadable data is treated as empty.
    }
    return GameStorage._withFile(file, data, problem);
  }

  final SharedPreferences? _prefs;
  final File? _file;

  /// Why SharedPreferences could not be used (null when it works).
  final String? problem;

  /// True when no storage could be opened, so nothing is kept.
  final bool saveFailed;
  final Map<String, Object> _memory = {};
  Future<void> _lastWrite = Future<void>.value();

  void _persist() {
    final file = _file;
    if (file == null) return;
    final text = jsonEncode(_memory);
    _lastWrite = _lastWrite.then((_) async {
      try {
        await file.writeAsString(text, flush: true);
      } catch (_) {
        // Saving is best effort.
      }
    });
  }

  /// Completes when everything written so far has reached the file.
  Future<void> flush() => _lastWrite;

  static const String _kBest = 'cuboo.best';
  static const String _kTheme = 'cuboo.theme';
  static const String _kSound = 'cuboo.sound';
  static const String _kHaptics = 'cuboo.haptics';
  static const String _kGame = 'cuboo.game';
  static const String _kBestRelaxed = 'cuboo.best.relaxed';
  static const String _kBestTimed = 'cuboo.best.timed';
  static const String _kDaily = 'cuboo.daily';
  static const String _kPalette = 'cuboo.palette';
  static const String _kBlockStyle = 'cuboo.blockStyle';
  static const String _kLeftHanded = 'cuboo.leftHanded';
  static const String _kStats = 'cuboo.stats';
  static const String _kHistory = 'cuboo.history';
  static const String _kAchievements = 'cuboo.achievements';
  static const String _kLaunches = 'cuboo.launches';

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
      _persist();
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
      _persist();
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

  /// How many times the app was opened (used to check that saving works).
  int get launches => _get<int>(_kLaunches, 0);
  Future<bool> setLaunches(int value) => _set(_kLaunches, value);

  int get palette => _get<int>(_kPalette, 0);
  Future<bool> setPalette(int value) => _set(_kPalette, value);

  int get blockStyle => _get<int>(_kBlockStyle, 0);
  Future<bool> setBlockStyle(int value) => _set(_kBlockStyle, value);

  bool get leftHanded => _get<bool>(_kLeftHanded, false);
  Future<bool> setLeftHanded(bool value) => _set(_kLeftHanded, value);

  /// Lifetime stats as JSON text ('' when there are none yet).
  String get statsJson => _get<String>(_kStats, '');
  Future<bool> saveStats(String json) => _set(_kStats, json);

  /// Recent scores, newest first, joined with commas.
  String get historyRaw => _get<String>(_kHistory, '');
  Future<bool> saveHistory(String raw) => _set(_kHistory, raw);

  /// Unlocked achievement ids, joined with commas.
  String get achievementsRaw => _get<String>(_kAchievements, '');
  Future<bool> saveAchievements(String raw) => _set(_kAchievements, raw);

  int get bestRelaxed => _get<int>(_kBestRelaxed, 0);
  Future<bool> setBestRelaxed(int value) => _set(_kBestRelaxed, value);

  int get bestTimed => _get<int>(_kBestTimed, 0);
  Future<bool> setBestTimed(int value) => _set(_kBestTimed, value);

  /// The best Daily Challenge score as "seed:score" ('' when none).
  String get dailyRaw => _get<String>(_kDaily, '');
  Future<bool> saveDaily(String raw) => _set(_kDaily, raw);
}
