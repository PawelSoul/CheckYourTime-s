import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/daos/sessions_dao.dart';
import '../../../../data/db/daos/tasks_dao.dart';
import '../../../../providers/app_db_provider.dart';

class TaskListItem extends ConsumerWidget {
  const TaskListItem({
    super.key,
    required this.task,
  });

  final TaskRow task;

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
    final tasksDao = ref.read(tasksDaoProvider);
    final sessionsDao = ref.read(sessionsDaoProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _parseColor(task.colorHex),
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
        context,
        ref,
        task,
        tasksDao,
        sessionsDao,
      ),
    );
  }

  static Future<void> _showTaskOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    TaskRow task,
    TasksDao tasksDao,
    SessionsDao sessionsDao,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
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
              leading: const Icon(Icons.edit),
              title: const Text('Edytuj nazwę'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
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

    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      await _showEditNameDialog(context, ref, task, tasksDao);
    } else if (action == 'delete') {
      final confirmed = await _showDeleteConfirmDialog(context);
      if (confirmed == true && context.mounted) {
        final taskId = task.id;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          await sessionsDao.deleteSessionsByTaskId(taskId);
          await tasksDao.deleteTask(taskId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zadanie usunięte')),
          );
        });
      }
    }
  }

  static Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    TaskRow task,
    TasksDao tasksDao,
  ) async {
    final controller = TextEditingController(text: task.name);
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nazwa zadania'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nazwa',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim().isEmpty ? null : v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                Navigator.of(ctx).pop(v.isEmpty ? null : v);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        final taskId = task.id;
        final nameToSave = name;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          await tasksDao.renameTask(taskId, name: nameToSave, nowMs: nowMs);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nazwa zapisana')),
          );
        });
      }
    } finally {
      controller.dispose();
    }
  }

  static Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć zadanie?'),
        content: const Text(
          'Zadanie i powiązane sesje zostaną trwale usunięte. Tej operacji nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
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
