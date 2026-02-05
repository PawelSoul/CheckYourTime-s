import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/category_colors.dart';
import '../../../../data/db/app_db.dart';
import '../../../../data/db/daos/sessions_dao.dart';
import '../../../tasks/tasks_providers.dart';

class SessionEventTile extends ConsumerWidget {
  const SessionEventTile({
    super.key,
    required this.sessionWithTask,
  });

  final SessionWithTask sessionWithTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = sessionWithTask.session;
    final task = sessionWithTask.task;
    final category = task.categoryId != null
        ? ref.watch(categoryByIdProvider(task.categoryId!))
        : null;
    final colorHex = category?.colorHex ?? task.colorHex;
    final start = DateTime.fromMillisecondsSinceEpoch(session.startAt);
    final endMs = session.endAt;
    final hasEnd = endMs != null;
    final end = hasEnd ? DateTime.fromMillisecondsSinceEpoch(endMs) : null;
    final durationSec = session.durationSec;

    final timeStr = hasEnd && end != null
        ? '${_timeStr(start)} – ${_timeStr(end)}'
        : 'od ${_timeStr(start)}';
    final durationStr = durationSec > 0 ? _formatDuration(durationSec) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: CategoryColors.parse(colorHex),
          child: Text(
            task.name.isNotEmpty ? task.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        title: Text(task.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timeStr, style: Theme.of(context).textTheme.bodySmall),
            if (durationStr != null)
              Text(durationStr, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static String _timeStr(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDuration(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m} min';
  }

}
