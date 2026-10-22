import 'dart:io';

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

  test('the file backup keeps data between restarts', () async {
    final dir = Directory.systemTemp.createTempSync('cuboo_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/cuboo_data.json');

    final first = await GameStorage.openFile(file, problem: 'test');
    expect(first.saveFailed, isFalse);
    expect(first.problem, 'test');
    final app = AppState(first);
    app.submitScore(900);
    app.recordMove(lines: 1, combo: 1, score: 900);
    app.recordGameOver(900);
    await first.flush();

    final second = await GameStorage.openFile(file);
    final again = AppState(second);
    expect(again.best, 900);
    expect(again.history, [900]);
    expect(again.stats.totalLines, 1);
    expect(again.unlocked, contains('first_clear'));
    expect(again.launches, 2);
  });

  test('a broken backup file is treated as empty', () async {
    final dir = Directory.systemTemp.createTempSync('cuboo_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/cuboo_data.json');
    file.writeAsStringSync('{ not json');
    final storage = await GameStorage.openFile(file);
    expect(storage.best, 0);
    expect(AppState(storage).launches, 1);
  });

  test('an old backup file is moved into the normal storage', () async {
    SharedPreferences.setMockInitialValues({'cuboo.best': 70});
    SharedPreferences.resetStatic();
    final prefs = await SharedPreferences.getInstance();

    final dir = Directory.systemTemp.createTempSync('cuboo_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/cuboo_data.json');
    file.writeAsStringSync(
      '{"cuboo.best": 900, "cuboo.stats": "x", "cuboo.sound": false, "other": 1}',
    );

    await GameStorage.importBackup(prefs, file);

    expect(prefs.getInt('cuboo.best'), 70); // already there, kept
    expect(prefs.getString('cuboo.stats'), 'x');
    expect(prefs.getBool('cuboo.sound'), false);
    expect(prefs.containsKey('other'), isFalse);
    expect(file.existsSync(), isFalse);
    expect(File('${file.path}.migrated').existsSync(), isTrue);
  });
}
