import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_state.dart';
import '../theme.dart';
import '../update_service.dart';
import '../widgets/buttons.dart';
import '../widgets/scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.app});

  final AppState app;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      if (mounted) setState(() => _version = '');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    UpdateInfo? info;
    var failed = false;
    try {
      info = await UpdateChecker.check();
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() => _checking = false);
    if (failed) {
      _snack('Could not check for updates. Check your connection.');
      return;
    }
    final update = info;
    if (update == null) {
      _snack('Cuboo is up to date.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _UpdateDialog(info: update),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return CubooScaffold(
      child: ListenableBuilder(
        listenable: widget.app,
        builder: (context, _) {
          final app = widget.app;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  IconSquareButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Play'),
              _Card(
                children: [
                  SwitchListTile(
                    value: app.sound,
                    onChanged: app.setSound,
                    title: const _TileTitle('Sound'),
                    subtitle:
                        const _TileSubtitle('A soft click when you place blocks'),
                  ),
                  SwitchListTile(
                    value: app.haptics,
                    onChanged: app.setHaptics,
                    title: const _TileTitle('Vibration'),
                    subtitle:
                        const _TileSubtitle('Gentle feedback while you play'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Theme'),
              _Card(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('System'),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Light'),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {app.themeMode},
                        onSelectionChanged: (selection) =>
                            app.setThemeMode(selection.first),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Updates'),
              _Card(
                children: [
                  ListTile(
                    onTap: _checking ? null : _checkUpdates,
                    leading: Icon(Icons.system_update_rounded, color: c.text),
                    title: const _TileTitle('Check for updates'),
                    subtitle: _TileSubtitle(
                      _checking
                          ? 'Checking...'
                          : 'Asks GitHub if a newer version exists',
                    ),
                    trailing: _checking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('About'),
              _Card(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _version.isEmpty ? 'Cuboo' : 'Cuboo $_version',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cuboo is free and open source. No ads, no tracking, '
                          'no accounts. Your scores and settings stay on your '
                          'phone. The only time Cuboo uses the internet is when '
                          'you tap "Check for updates".',
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'github.com/$kGithubOwner/$kGithubRepo',
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: c.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _TileTitle extends StatelessWidget {
  const _TileTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return Text(
      text,
      style: TextStyle(
        color: c.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TileSubtitle extends StatelessWidget {
  const _TileSubtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return Text(text, style: TextStyle(color: c.muted, fontSize: 14));
  }
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.info});

  final UpdateInfo info;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  bool _failed = false;

  Future<void> _install() async {
    setState(() {
      _progress = 0;
      _failed = false;
    });
    try {
      await UpdateChecker.downloadAndInstall(widget.info, (value) {
        if (mounted) setState(() => _progress = value);
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = null;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final downloading = _progress != null;
    final notes = widget.info.notes;
    return AlertDialog(
      backgroundColor: c.surface,
      title: Text(
        'Update available',
        style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuboo ${widget.info.version} is ready to install. '
              'Your scores and settings are kept.',
              style: TextStyle(color: c.text),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: SingleChildScrollView(
                  child: Text(notes, style: TextStyle(color: c.muted)),
                ),
              ),
            ],
            if (downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
            ],
            if (_failed) ...[
              const SizedBox(height: 12),
              const Text(
                'The download failed. Please try again.',
                style: TextStyle(color: Color(0xFFFF6B5B)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: downloading ? null : () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: downloading ? null : _install,
          child: Text(downloading ? 'Downloading...' : 'Update'),
        ),
      ],
    );
  }
}
