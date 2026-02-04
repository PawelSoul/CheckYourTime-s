import 'package:flutter/material.dart';

import '../../../../data/db/daos/sessions_dao.dart';
import 'session_event_tile.dart';

class DayScheduleView extends StatelessWidget {
  const DayScheduleView({
    super.key,
    required this.day,
    required this.sessionsInMonth,
  });

  final DateTime day;
  final List<SessionWithTask> sessionsInMonth;

  static List<SessionWithTask> _sessionsForDay(
    DateTime day,
    List<SessionWithTask> sessions,
  ) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final fromMs = startOfDay.millisecondsSinceEpoch;
    final toMs = endOfDay.millisecondsSinceEpoch;

    return sessions.where((s) {
      final ms = s.session.startAt;
      return ms >= fromMs && ms < toMs;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessionsForDay(day, sessionsInMonth);
    final dayStr = '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Brak sesji w dniu $dayStr',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Sesje – $dayStr',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...sessions.map((s) => SessionEventTile(sessionWithTask: s)),
      ],
    );
  }
}
