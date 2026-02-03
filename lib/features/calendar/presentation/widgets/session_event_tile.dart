import 'package:flutter/material.dart';

import '../../../../data/db/app_db.dart';
import '../../../../data/db/daos/sessions_dao.dart';

class SessionEventTile extends StatelessWidget {
  const SessionEventTile({
    super.key,
    required this.sessionWithTask,
  });

  final SessionWithTask sessionWithTask;

  @override
  Widget build(BuildContext context) {
    final session = sessionWithTask.session;
    final task = sessionWithTask.task;
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
          backgroundColor: _parseColor(task.colorHex),
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

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }
}
