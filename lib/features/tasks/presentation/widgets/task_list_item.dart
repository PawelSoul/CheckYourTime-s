import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../../../data/db/daos/tasks_dao.dart';

class TaskListItem extends ConsumerWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.scaffoldContext,
    required this.onDeleteTask,
    this.categoryColorHex,
  });

  final TaskRow task;
  final BuildContext scaffoldContext;
  final void Function(TaskRow task) onDeleteTask;
  /// Kolor kategorii – używany zamiast task.colorHex, gdy zadanie jest w kategorii.
  final String? categoryColorHex;

  static String _formatDateTime(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorHex = categoryColorHex ?? task.colorHex;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: CategoryColors.parse(colorHex),
        child: Text(
          task.name.isNotEmpty ? task.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(task.name),
      subtitle: Text(
        _formatDateTime(task.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => _showTaskOptionsSheet(
        scaffoldContext,
        task,
        onDeleteTask,
      ),
    );
  }

  static Future<void> _showTaskOptionsSheet(
    BuildContext scaffoldContext,
    TaskRow task,
    void Function(TaskRow task) onDeleteTask,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: scaffoldContext,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                task.name,
                style: Theme.of(ctx).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
              title: Text(
                'Usuń zadanie',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!scaffoldContext.mounted || action == null) return;

    if (action == 'delete') {
      onDeleteTask(task);
    }
  }

}
