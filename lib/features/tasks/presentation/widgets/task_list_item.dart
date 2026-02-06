import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../../../data/db/daos/tasks_dao.dart';
import '../../../../providers/app_db_provider.dart';

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
        ref,
        task,
        onDeleteTask,
      ),
    );
  }

  static Future<void> _showTaskOptionsSheet(
    BuildContext scaffoldContext,
    WidgetRef ref,
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
              leading: const Icon(Icons.edit_outlined),
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

    if (!scaffoldContext.mounted || action == null) return;

    if (action == 'edit') {
      await _showEditTaskDialog(scaffoldContext, ref, task);
    } else if (action == 'delete') {
      onDeleteTask(task);
    }
  }

  static Future<void> _showEditTaskDialog(
    BuildContext context,
    WidgetRef ref,
    TaskRow task,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditTaskDialogContent(task: task),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await ref.read(tasksDaoProvider).renameTask(task.id, name: name, nowMs: nowMs);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nazwa zadania zapisana')),
    );
  }
}

/// Dialog edycji nazwy zadania – controller w initState/dispose (jak przy kategorii).
class _EditTaskDialogContent extends StatefulWidget {
  const _EditTaskDialogContent({required this.task});

  final TaskRow task;

  @override
  State<_EditTaskDialogContent> createState() => _EditTaskDialogContentState();
}

class _EditTaskDialogContentState extends State<_EditTaskDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nazwa zadania'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nazwa',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) {
          final trimmed = v.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            final v = _controller.text.trim();
            Navigator.of(context).pop(v.isEmpty ? null : v);
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}
