import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class CubooApp extends StatelessWidget {
  const CubooApp({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'Cuboo',
        debugShowCheckedModeBanner: false,
        themeMode: app.themeMode,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: HomeScreen(app: app),
      ),
    );
  }
}
