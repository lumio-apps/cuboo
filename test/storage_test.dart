import 'package:cuboo/app_state.dart';
import 'package:cuboo/game/mode.dart';
import 'package:cuboo/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// These tests use the real SharedPreferences code (with a fake phone
/// storage behind it), to prove that data survives closing the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> openApp() async {
    SharedPreferences.resetStatic();
    final prefs = await SharedPreferences.getInstance();
    return AppState(GameStorage(prefs));
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('scores, stats, history and achievements survive a restart', () async {
    SharedPreferences.setMockInitialValues({});

    final first = await openApp();
    expect(first.launches, 1);
    first.submitScore(500);
    first.submitScore(300, mode: GameMode.timed);
    first.recordMove(lines: 3, combo: 2, score: 500);
    first.recordGameOver(500);
    first.setPalette(2);
    await settle();

    final second = await openApp();
    expect(second.launches, 2);
    expect(second.best, 500);
    expect(second.bestFor(GameMode.timed), 300);
    expect(second.stats.totalLines, 3);
    expect(second.stats.games, 1);
    expect(second.history, [500]);
    expect(second.unlocked, containsAll(['first_clear', 'triple']));
    expect(second.paletteIndex, 2);
    second.setPalette(0);

    await settle();
    final third = await openApp();
    expect(third.launches, 3);
  });
}
