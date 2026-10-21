import 'package:cuboo/app.dart';
import 'package:cuboo/app_state.dart';
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
