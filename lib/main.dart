import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_state.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets/logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // If something goes wrong, show the error text instead of a blank screen.
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
        color: kInk,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              details.exceptionAsString(),
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );

  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  runApp(const _Bootstrap());
}

/// Shows the logo straight away and opens the saved data in the background,
/// so the app never waits on the phone's storage before the first screen.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  AppState? _app;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    GameStorage storage;
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      storage = GameStorage(prefs);
    } catch (_) {
      // The game still works without saving.
      storage = GameStorage.inMemory();
    }
    if (!mounted) return;
    setState(() => _app = AppState(storage));
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    if (app != null) return CubooApp(key: const ValueKey<String>('app'), app: app);
    return const MaterialApp(
      key: ValueKey<String>('boot'),
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: kInk,
        child: Center(child: CubooLogo(size: 120, animate: false)),
      ),
    );
  }
}
