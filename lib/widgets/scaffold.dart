import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// A screen with the Cuboo background and matching status bar icons.
class CubooScaffold extends StatelessWidget {
  const CubooScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: c.bg,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(child: child),
      ),
    );
  }
}
