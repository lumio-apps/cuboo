import 'package:cuboo/app.dart';
import 'package:cuboo/app_state.dart';
import 'package:cuboo/game/mode.dart';
import 'package:cuboo/stats.dart';
import 'package:cuboo/storage.dart';
import 'package:cuboo/theme.dart';
import 'package:cuboo/update_service.dart';
import 'package:cuboo/widgets/piece_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the home screen shows the title, Play and the best score',
      (tester) async {
    final app = AppState(GameStorage.inMemory());
    await tester.pumpWidget(CubooApp(app: app));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cuboo'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Best score'), findsOneWidget);
    expect(find.text('Themes'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });

  testWidgets('Play opens the game with an empty board and a tray',
      (tester) async {
    final app = AppState(GameStorage.inMemory());
    await tester.pumpWidget(CubooApp(app: app));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('Undo (1 left)'), findsOneWidget);
    expect(find.byType(PieceView), findsNWidgets(3));
  });

  group('AppState', () {
    test('remembers settings and the best score', () {
      final storage = GameStorage.inMemory();
      final app = AppState(storage);
      expect(app.sound, isTrue);
      expect(app.haptics, isTrue);
      expect(app.themeMode, ThemeMode.system);
      expect(app.best, 0);

      app.setSound(false);
      app.setHaptics(false);
      app.setThemeMode(ThemeMode.dark);
      app.submitScore(120);
      app.submitScore(80); // lower, ignored

      final again = AppState(storage);
      expect(again.sound, isFalse);
      expect(again.haptics, isFalse);
      expect(again.themeMode, ThemeMode.dark);
      expect(again.best, 120);
    });
  });

  group('Stats and achievements', () {
    test('count moves and games, and unlock achievements once', () {
      final storage = GameStorage.inMemory();
      final app = AppState(storage);

      var fresh = app.recordMove(lines: 3, combo: 1, score: 40);
      expect(fresh.map((a) => a.id), containsAll(['first_clear', 'triple']));
      expect(app.stats.totalLines, 3);
      expect(app.stats.bestMoveLines, 3);

      fresh = app.recordMove(lines: 1, combo: 2, score: 60);
      expect(fresh, isEmpty);
      expect(app.stats.totalLines, 4);
      expect(app.stats.bestCombo, 2);

      app.recordGameOver(60);
      app.recordGameOver(100);
      expect(app.stats.games, 2);
      expect(app.stats.average, 80);
      expect(app.history, [100, 60]);

      final again = AppState(storage);
      expect(again.stats.totalLines, 4);
      expect(again.history, [100, 60]);
      expect(again.unlocked, containsAll(['first_clear', 'triple']));
    });

    test('history keeps only the latest ten scores', () {
      final app = AppState(GameStorage.inMemory());
      for (var i = 1; i <= 12; i++) {
        app.recordGameOver(i);
      }
      expect(app.history.length, 10);
      expect(app.history.first, 12);
      expect(app.history.last, 3);
    });

    test('broken saved stats give empty stats', () {
      expect(Stats.parse('not json').games, 0);
      expect(Stats.parse('').totalLines, 0);
    });

    test('block look and left-handed mode are remembered', () {
      final storage = GameStorage.inMemory();
      final app = AppState(storage);
      app.setPalette(2);
      app.setBlockStyle(BlockStyle.glossy);
      app.setLeftHanded(true);
      final again = AppState(storage);
      expect(again.paletteIndex, 2);
      expect(again.blockStyle, BlockStyle.glossy);
      expect(again.leftHanded, isTrue);
      // Put the global look back for other tests.
      again.setPalette(0);
      again.setBlockStyle(BlockStyle.flat);
    });
  });

  group('Mode scores', () {
    test('each mode keeps its own best score', () {
      final storage = GameStorage.inMemory();
      final app = AppState(storage);
      app.submitScore(100);
      app.submitScore(50, mode: GameMode.timed);
      app.submitScore(70, mode: GameMode.relaxed);
      app.submitScore(30, mode: GameMode.daily);
      app.submitScore(20, mode: GameMode.timed); // lower, ignored
      expect(app.bestFor(GameMode.classic), 100);
      expect(app.bestFor(GameMode.timed), 50);
      expect(app.bestFor(GameMode.relaxed), 70);
      expect(app.bestFor(GameMode.daily), 30);

      final again = AppState(storage);
      expect(again.bestFor(GameMode.timed), 50);
      expect(again.bestFor(GameMode.daily), 30);
    });
  });

  group('GameStorage', () {
    test('saves and clears a running game', () {
      final storage = GameStorage.inMemory();
      expect(storage.savedGame, isNull);
      storage.saveGame('{"a":1}');
      expect(storage.savedGame, '{"a":1}');
      storage.clearGame();
      expect(storage.savedGame, isNull);
    });
  });

  group('formatScore', () {
    test('adds thousands separators', () {
      expect(formatScore(0), '0');
      expect(formatScore(999), '999');
      expect(formatScore(1000), '1,000');
      expect(formatScore(12480), '12,480');
      expect(formatScore(1234567), '1,234,567');
    });
  });

  group('UpdateChecker.isNewer', () {
    test('compares versions', () {
      expect(UpdateChecker.isNewer('1.0.1', '1.0.0'), isTrue);
      expect(UpdateChecker.isNewer('1.1.0', '1.0.9'), isTrue);
      expect(UpdateChecker.isNewer('2.0.0', '1.9.9'), isTrue);
      expect(UpdateChecker.isNewer('1.0.0', '1.0.0'), isFalse);
      expect(UpdateChecker.isNewer('1.0.0', '1.0.1'), isFalse);
      expect(UpdateChecker.isNewer('1.2.0', '1.1.0+5'), isTrue);
      expect(UpdateChecker.isNewer('1.1.0', '1.1.0+5'), isFalse);
      expect(UpdateChecker.isNewer('1.10.0', '1.9.0'), isTrue);
    });
  });
}
