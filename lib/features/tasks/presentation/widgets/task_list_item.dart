import 'package:flutter/material.dart';

import '../../../../data/db/daos/tasks_dao.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({
    super.key,
    required this.task,
  });

  final TaskRow task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _parseColor(task.colorHex),
        child: Text(
          task.name.isNotEmpty ? task.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(task.name),
      subtitle: task.tag != null && task.tag!.isNotEmpty
          ? Text(task.tag!, style: Theme.of(context).textTheme.bodySmall)
          : null,
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }
}
