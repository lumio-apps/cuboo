import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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
    // Wait patiently for the phone's storage. Starting without it would mean
    // that nothing is saved, so it is only a last resort.
    GameStorage? storage;
    Object? error;
    for (var attempt = 0; attempt < 3 && storage == null; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 10));
        await _importOldBackup(prefs);
        storage = GameStorage(prefs);
      } catch (e) {
        error = e;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    // If the phone will not open its preferences, save into a file instead.
    storage ??= await _openBackup(error);
    if (!mounted) return;
    final app = AppState(storage);
    setState(() => _app = app);
    app.warmUpSound();
  }

  /// The private folders where the backup file may live.
  Future<List<Directory>> _backupFolders() async {
    final folders = <Directory>[];
    try {
      folders.add(await getApplicationSupportDirectory());
    } catch (_) {
      // Try the next folder.
    }
    try {
      final temp = Directory.systemTemp;
      if (temp.path.contains('cuboo')) {
        folders.add(Directory('${temp.parent.path}/files'));
      }
    } catch (_) {
      // Nothing more to try.
    }
    return folders;
  }

  /// When an earlier version had to save into a backup file, its data is
  /// moved into the normal storage once that works again.
  Future<void> _importOldBackup(SharedPreferences prefs) async {
    for (final folder in await _backupFolders()) {
      await GameStorage.importBackup(
        prefs,
        File('${folder.path}/cuboo_data.json'),
      );
    }
  }

  Future<GameStorage> _openBackup(Object? error) async {
    var problem = (error ?? 'unknown').toString().replaceAll('\n', ' ');
    if (problem.length > 160) problem = problem.substring(0, 160);
    for (final folder in await _backupFolders()) {
      try {
        await folder.create(recursive: true);
        final file = File('${folder.path}/cuboo_data.json');
        if (!await file.exists()) await file.writeAsString('{}', flush: true);
        return await GameStorage.openFile(file, problem: problem);
      } catch (_) {
        // Try the next folder.
      }
    }
    // The game still works without saving.
    return GameStorage.unavailable(problem: problem);
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
