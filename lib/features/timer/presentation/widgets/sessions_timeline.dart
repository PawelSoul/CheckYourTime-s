import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import 'package:checkyourtime/core/widgets/glass_card.dart';
import '../../../../data/db/daos/categories_dao.dart';
import '../../../../data/db/daos/sessions_dao.dart';
import '../../../tasks/tasks_providers.dart';
import '../../application/recent_sessions_provider.dart';

/// Tryb sortowania osi czasu sesji.
enum SessionsTimelineSort { newestFirst, oldestFirst }

final _sessionsTimelineSortProvider =
    StateProvider<SessionsTimelineSort>((ref) => SessionsTimelineSort.newestFirst);

class SessionsTimeline extends ConsumerWidget {
  const SessionsTimeline({super.key});

  static String _dateGroupKey(DateTime date, DateTime today) {
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(d).inDays;
    if (diff == 0) return 'Dziś';
    if (diff == 1) return 'Wczoraj';
    final m = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day.$m.${date.year}';
  }

  static String _timeStr(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    final s = d.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0 && s > 0) return '$m min $s s';
    if (m > 0) return '$m min';
    return '$s s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final sortMode = ref.watch(_sessionsTimelineSortProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Brak zapisanych sesji',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uruchom stoper i zatrzymaj go,\nżeby pojawiły się tutaj.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final sorted = List<SessionWithTask>.from(sessions)
          ..sort((a, b) => sortMode == SessionsTimelineSort.newestFirst
              ? b.session.startAt.compareTo(a.session.startAt)
              : a.session.startAt.compareTo(b.session.startAt));

        final today = DateTime.now();
        final groups = <String, List<SessionWithTask>>{};
        for (final s in sorted) {
          final date = DateTime.fromMillisecondsSinceEpoch(s.session.startAt);
          final key = _dateGroupKey(date, today);
          groups.putIfAbsent(key, () => []).add(s);
        }
        final orderedKeys = groups.keys.toList()
          ..sort((a, b) {
            final listA = groups[a]!;
            final listB = groups[b]!;
            final dateA = listA.first.session.startAt;
            final dateB = listB.first.session.startAt;
            return sortMode == SessionsTimelineSort.newestFirst
                ? dateB.compareTo(dateA)
                : dateA.compareTo(dateB);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ostatnie sesje',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SegmentedButton<SessionsTimelineSort>(
                    segments: const [
                      ButtonSegment<SessionsTimelineSort>(
                        value: SessionsTimelineSort.newestFirst,
                        label: Text('Najnowsze'),
                      ),
                      ButtonSegment<SessionsTimelineSort>(
                        value: SessionsTimelineSort.oldestFirst,
                        label: Text('Najstarsze'),
                      ),
                    ],
                    selected: {sortMode},
                    onSelectionChanged: (s) {
                      ref.read(_sessionsTimelineSortProvider.notifier).state = s.first;
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.5);
                        }
                        return Colors.white.withOpacity(0.04);
                      }),
                    ),
                  ),
                ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...orderedKeys.map((key) {
              final list = groups[key]!;
              return _TimelineGroup(
                title: key,
                sessions: list,
                categories: categories,
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Błąd: $err',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}

class _TimelineGroup extends StatelessWidget {
  const _TimelineGroup({
    required this.title,
    required this.sessions,
    required this.categories,
  });

  final String title;
  final List<SessionWithTask> sessions;
  final List<CategoryRow> categories;

  Color _colorFor(SessionWithTask s) {
    final id = s.task.categoryId;
    if (id == null || id.isEmpty) return CategoryColors.parse(null);
    try {
      final c = categories.firstWhere((c) => c.id == id);
      return CategoryColors.parse(c.colorHex);
    } catch (_) {
      return CategoryColors.parse(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...List.generate(sessions.length, (index) {
            final s = sessions[index];
            final color = _colorFor(s);
            final start = DateTime.fromMillisecondsSinceEpoch(s.session.startAt);
            final endMs = s.session.endAt;
            final hasEnd = endMs != null;
            final end = hasEnd ? DateTime.fromMillisecondsSinceEpoch(endMs) : null;
            final timeMeta = hasEnd && end != null
                ? '${SessionsTimeline._timeStr(start)}–${SessionsTimeline._timeStr(end)} • ${SessionsTimeline._formatDuration(s.session.durationSec)}'
                : '${SessionsTimeline._timeStr(start)} • ${SessionsTimeline._formatDuration(s.session.durationSec)}';
            final isFirst = index == 0;
            final isLast = index == sessions.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        if (!isFirst)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        borderRadius: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.task.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeMeta,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
