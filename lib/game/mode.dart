/// The ways to play Cuboo.
enum GameMode { classic, relaxed, timed, daily }

/// How long a Timed game lasts.
const int kTimedSeconds = 120;

extension GameModeInfo on GameMode {
  String get title {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.relaxed:
        return 'Relaxed';
      case GameMode.timed:
        return 'Timed';
      case GameMode.daily:
        return 'Daily Challenge';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return 'The normal game. It ends when no piece fits.';
      case GameMode.relaxed:
        return 'Never ends. When you are stuck, the board is cleared.';
      case GameMode.timed:
        return 'Score as much as you can in 2 minutes.';
      case GameMode.daily:
        return 'The same pieces for everyone today. Play it as often as you like.';
    }
  }

  static GameMode parse(Object? name) {
    for (final mode in GameMode.values) {
      if (mode.name == name) return mode;
    }
    return GameMode.classic;
  }
}

/// A number that is the same all day long, used as the seed of the Daily
/// Challenge (for example 20261021).
int dailySeed(DateTime day) => day.year * 10000 + day.month * 100 + day.day;
