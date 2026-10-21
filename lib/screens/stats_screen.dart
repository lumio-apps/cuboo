import 'package:flutter/material.dart';

import '../app_state.dart';
import '../stats.dart';
import '../theme.dart';
import '../widgets/scaffold.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return CubooScaffold(
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final stats = app.stats;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_rounded, color: c.text),
                    tooltip: 'Back',
                  ),
                  Text(
                    'Stats',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Grid(
                items: [
                  _Item('Best score', formatScore(app.best)),
                  _Item('Games played', formatScore(stats.games)),
                  _Item('Average score', formatScore(stats.average)),
                  _Item('Lines cleared', formatScore(stats.totalLines)),
                  _Item('Best combo', 'x${stats.bestCombo}'),
                  _Item('Most lines in a move', '${stats.bestMoveLines}'),
                ],
              ),
              const SizedBox(height: 24),
              const _Title('Recent scores'),
              _Panel(
                child: app.history.isEmpty
                    ? Text(
                        'Finish a game to see your scores here.',
                        style: TextStyle(color: c.muted, fontSize: 15),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < app.history.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${i + 1}',
                                    style: TextStyle(
                                      color: c.muted,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    formatScore(app.history[i]),
                                    style: TextStyle(
                                      color: c.text,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              _Title(
                'Achievements  ${app.unlocked.length}/${kAchievements.length}',
              ),
              _Panel(
                child: Column(
                  children: [
                    for (final a in kAchievements)
                      _AchievementRow(
                        achievement: a,
                        unlocked: app.unlocked.contains(a.id),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Item {
  const _Item(this.label, this.value);

  final String label;
  final String value;
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          LayoutBuilder(
            builder: (context, _) {
              final width = (MediaQuery.sizeOf(context).width - 40 - 12) / 2;
              return SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(color: c.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.value,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: unlocked ? c.bestText : c.muted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: unlocked ? c.text : c.muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
