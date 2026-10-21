import 'dart:convert';

/// Lifetime numbers shown on the Stats screen.
class Stats {
  const Stats({
    this.games = 0,
    this.totalScore = 0,
    this.totalLines = 0,
    this.bestCombo = 0,
    this.bestMoveLines = 0,
  });

  final int games;
  final int totalScore;
  final int totalLines;
  final int bestCombo;

  /// The most lines cleared by one single move.
  final int bestMoveLines;

  int get average => games == 0 ? 0 : (totalScore / games).round();

  Stats copyWith({
    int? games,
    int? totalScore,
    int? totalLines,
    int? bestCombo,
    int? bestMoveLines,
  }) =>
      Stats(
        games: games ?? this.games,
        totalScore: totalScore ?? this.totalScore,
        totalLines: totalLines ?? this.totalLines,
        bestCombo: bestCombo ?? this.bestCombo,
        bestMoveLines: bestMoveLines ?? this.bestMoveLines,
      );

  String toJsonString() => jsonEncode({
        'games': games,
        'totalScore': totalScore,
        'totalLines': totalLines,
        'bestCombo': bestCombo,
        'bestMoveLines': bestMoveLines,
      });

  /// Reads saved stats. Anything unreadable gives empty stats.
  static Stats parse(String raw) {
    if (raw.isEmpty) return const Stats();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      int read(String key) {
        final value = map[key];
        return value is int && value >= 0 ? value : 0;
      }

      return Stats(
        games: read('games'),
        totalScore: read('totalScore'),
        totalLines: read('totalLines'),
        bestCombo: read('bestCombo'),
        bestMoveLines: read('bestMoveLines'),
      );
    } catch (_) {
      return const Stats();
    }
  }
}

/// Something the player can unlock.
class Achievement {
  const Achievement(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;
}

/// The ids are saved on the phone, so they must never change.
const List<Achievement> kAchievements = [
  Achievement('first_clear', 'First clear', 'Clear your first line'),
  Achievement('triple', 'Triple', 'Clear 3 lines with one move'),
  Achievement('five_at_once', 'Five at once', 'Clear 5 lines with one move'),
  Achievement('combo5', 'Combo x5', 'Reach a combo of 5'),
  Achievement('combo10', 'Combo x10', 'Reach a combo of 10'),
  Achievement('score1000', '1,000 points', 'Score 1,000 in one game'),
  Achievement('score5000', '5,000 points', 'Score 5,000 in one game'),
  Achievement('lines100', 'Line master', 'Clear 100 lines in total'),
  Achievement('games10', 'Regular', 'Play 10 games'),
];

/// Whether [id] is earned, given the lifetime [stats] and the best score.
bool isEarned(String id, Stats stats, int bestScore) {
  switch (id) {
    case 'first_clear':
      return stats.totalLines >= 1;
    case 'triple':
      return stats.bestMoveLines >= 3;
    case 'five_at_once':
      return stats.bestMoveLines >= 5;
    case 'combo5':
      return stats.bestCombo >= 5;
    case 'combo10':
      return stats.bestCombo >= 10;
    case 'score1000':
      return bestScore >= 1000;
    case 'score5000':
      return bestScore >= 5000;
    case 'lines100':
      return stats.totalLines >= 100;
    case 'games10':
      return stats.games >= 10;
  }
  return false;
}
