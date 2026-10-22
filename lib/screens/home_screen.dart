import 'package:flutter/material.dart';

import '../app_state.dart';
import '../game/mode.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/logo.dart';
import '../widgets/scaffold.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.app});

  final AppState app;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _openGame() async {
    widget.app.tapFeedback();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(app: widget.app),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _startMode(GameMode mode) async {
    if (widget.app.storage.savedGame != null) {
      final c = CubooColors.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: c.surface,
          title: Text(
            'Start a new game?',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Your game in progress will be replaced.',
            style: TextStyle(color: c.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    if (!mounted) return;
    widget.app.tapFeedback();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(app: widget.app, mode: mode, startNew: true),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openModes() {
    widget.app.tapFeedback();
    final c = CubooColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game modes',
                style: TextStyle(
                  color: c.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final mode in GameMode.values)
                _ModeTile(
                  mode: mode,
                  best: widget.app.bestFor(mode),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _startMode(mode);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    widget.app.tapFeedback();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(app: widget.app),
      ),
    );
  }

  void _openStats() {
    widget.app.tapFeedback();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatsScreen(app: widget.app),
      ),
    );
  }

  void _openThemes() {
    widget.app.tapFeedback();
    final c = CubooColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ListenableBuilder(
        listenable: widget.app,
        builder: (context, _) => _ThemeSheet(app: widget.app),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return CubooScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final small = constraints.maxHeight < 620;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                  child: ListenableBuilder(
                    listenable: widget.app,
                    builder: (context, _) {
                      final hasSaved = widget.app.storage.savedGame != null;
                      return Column(
                        children: [
                          SizedBox(
                            width: small ? 110 : 148,
                            height: small ? 110 : 148,
                            child: CubooLogo(size: small ? 110 : 148),
                          ),
                          SizedBox(height: small ? 12 : 22),
                          Text(
                            'Cuboo',
                            style: TextStyle(
                              color: c.text,
                              fontSize: small ? 48 : 60,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Block puzzle',
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.app.storage.saveFailed)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'Saving is not available right now, so '
                                'scores will not be kept. Restart the app.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: c.muted, fontSize: 13),
                              ),
                            ),
                          const Spacer(),
                          ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 1.04).animate(
                              CurvedAnimation(
                                parent: _pulse,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: ChunkyButton(
                              label: hasSaved ? 'Continue' : 'Play',
                              icon: Icons.play_arrow_rounded,
                              shadowColor: c.buttonShadow,
                              onPressed: _openGame,
                            ),
                          ),
                          const SizedBox(height: 20),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 22),
                              child: SizedBox(
                                height: 64,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Best score',
                                      style: TextStyle(
                                        color: c.muted,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      formatScore(widget.app.best),
                                      style: TextStyle(
                                        color: c.bestText,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SoftButton(
                                  label: 'Themes',
                                  icon: Icons.grid_view_rounded,
                                  height: 64,
                                  onPressed: _openThemes,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SoftButton(
                                  label: 'Stats',
                                  icon: Icons.bar_chart_rounded,
                                  height: 64,
                                  onPressed: _openStats,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SoftButton(
                                  label: 'Modes',
                                  icon: Icons.extension_rounded,
                                  height: 64,
                                  onPressed: _openModes,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SoftButton(
                                  label: 'Settings',
                                  icon: Icons.tune_rounded,
                                  height: 64,
                                  onPressed: _openSettings,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Offline · No ads · No tracking',
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: TextStyle(
                color: c.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ThemeOption(
                    label: 'System',
                    selected: app.themeMode == ThemeMode.system,
                    onTap: () => app.setThemeMode(ThemeMode.system),
                    left: CubooColors.light.bg,
                    right: CubooColors.dark.bg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOption(
                    label: 'Light',
                    selected: app.themeMode == ThemeMode.light,
                    onTap: () => app.setThemeMode(ThemeMode.light),
                    left: CubooColors.light.bg,
                    right: CubooColors.light.bg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOption(
                    label: 'Dark',
                    selected: app.themeMode == ThemeMode.dark,
                    onTap: () => app.setThemeMode(ThemeMode.dark),
                    left: CubooColors.dark.bg,
                    right: CubooColors.dark.bg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Block colours',
              style: TextStyle(
                color: c.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < kPalettes.length; i++)
                  _PaletteChip(
                    palette: kPalettes[i],
                    selected: app.paletteIndex == i,
                    onTap: () => app.setPalette(i),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Block style',
              style: TextStyle(
                color: c.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<BlockStyle>(
                segments: const [
                  ButtonSegment<BlockStyle>(
                    value: BlockStyle.flat,
                    label: Text('Flat'),
                  ),
                  ButtonSegment<BlockStyle>(
                    value: BlockStyle.glossy,
                    label: Text('Glossy'),
                  ),
                  ButtonSegment<BlockStyle>(
                    value: BlockStyle.outlined,
                    label: Text('Outline'),
                  ),
                ],
                selected: {app.blockStyle},
                onSelectionChanged: (selection) =>
                    app.setBlockStyle(selection.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final BlockPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.name} block colours',
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: c.surfaceAlt,
            border: Border.all(
              color: selected ? kCoral : Colors.transparent,
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final color in palette.colors)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const SizedBox(width: 14, height: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  palette.name,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.left,
    required this.right,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color left;
  final Color right;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 0.85,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: selected ? kCoral : c.muted.withValues(alpha: 0.4),
                    width: selected ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(child: ColoredBox(color: left)),
                          Expanded(child: ColoredBox(color: right)),
                        ],
                      ),
                      const Center(child: _MiniBlocks()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: c.text,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBlocks extends StatelessWidget {
  const _MiniBlocks();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: kBlockColors[i],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const SizedBox(width: 14, height: 14),
          ),
        ],
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.best,
    required this.onTap,
  });

  final GameMode mode;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final radius = BorderRadius.circular(18);
    final bestLabel = mode == GameMode.daily ? "Today's best" : 'Best';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.surfaceAlt,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.title,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.description,
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bestLabel,
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                    Text(
                      formatScore(best),
                      style: TextStyle(
                        color: c.bestText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
