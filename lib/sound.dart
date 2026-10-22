import 'package:audioplayers/audioplayers.dart';

/// The short sound effects. They are bundled in the app, nothing is
/// downloaded. Every failure is ignored: the game works without sound.
class SoundPlayer {
  final Map<String, AudioPlayer> _players = {};

  static const List<String> _names = ['place', 'clear', 'combo', 'over', 'bomb'];

  /// Creates the players up front. Making one in the middle of a move can
  /// make the game stutter.
  Future<void> warmUp() async {
    for (final name in _names) {
      try {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource('sounds/$name.wav'));
        _players[name] = player;
      } catch (_) {
        // Ignored: play() tries again later.
      }
    }
  }

  Future<void> play(String name, {double volume = 0.6}) async {
    try {
      var player = _players[name];
      if (player == null) {
        player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        _players[name] = player;
      }
      await player.play(AssetSource('sounds/$name.wav'), volume: volume);
    } catch (_) {
      // No sound is better than a crash.
      _players.remove(name);
    }
  }
}
