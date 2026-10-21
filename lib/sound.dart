import 'package:audioplayers/audioplayers.dart';

/// The short sound effects. They are bundled in the app, nothing is
/// downloaded. Every failure is ignored: the game works without sound.
class SoundPlayer {
  final Map<String, AudioPlayer> _players = {};

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
