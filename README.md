# Cuboo

A calm block puzzle for Android. Drag pieces onto an 8x8 board, complete rows and columns to clear them, and keep going as long as you can.

Fully offline. No ads. No tracking. Open source.

## How to play

- Three pieces wait at the bottom. Drag one onto the board.
- Fill a whole row or column to clear it. Clear several at once for more points.
- Clear lines on back-to-back moves to build a **combo** and multiply your score.
- When none of the pieces fit anymore, the game is over.
- You get **one undo** per game.

## Features

- Light, dark or system theme
- Smooth animations (they switch off automatically if your phone asks to reduce motion)
- Sound and vibration, each with its own switch
- Your best score and your running game are saved on the phone
- In-app **Check for updates** that installs new versions from GitHub Releases

## Privacy

- No ads, no analytics, no accounts, no trackers.
- Scores, settings and the game in progress are stored **only on your phone**.
- The only network request is when you tap **Check for updates**: Cuboo asks the GitHub API for the newest release and, if you agree, downloads the APK from GitHub Releases. Nothing about you or your phone is sent.

## Build from source

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) and an Android device or emulator.

```sh
git clone https://github.com/lumio-apps/cuboo.git
cd cuboo
flutter pub get
flutter run
```

Run the checks:

```sh
flutter analyze
flutter test
```

### Project layout

```
lib/
  game/        Game rules (pure Dart): shapes, board, scoring, undo
  screens/     Home, Game and Settings screens
  widgets/     Logo, board, pieces, buttons, game over card
  theme.dart   Light and dark colours
  ...          App state, storage, update checker
test/          Unit and widget tests
```

The game rules in `lib/game/` have no Flutter dependency, so they are easy to test and reuse.

## Releases

Pushing a version tag such as `v1.0.0` starts the **Release** workflow. It builds the APK, signs it with the key stored in the repository secrets and publishes it on GitHub Releases. Pushes to `main` run the **CI** workflow (`flutter analyze` and `flutter test`).

Required repository secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

## Contributing

Bug reports and ideas are welcome in [Issues](https://github.com/lumio-apps/cuboo/issues). Please keep in mind the rules of the project: offline first, no ads, no tracking.

## License

MIT, see [LICENSE](LICENSE).
