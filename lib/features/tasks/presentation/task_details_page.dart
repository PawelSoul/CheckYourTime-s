import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import 'package:checkyourtime/core/utils/datetime_utils.dart';
import 'package:checkyourtime/core/widgets/glass_card.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../calendar/application/calendar_providers.dart';
import 'widgets/task_list_item.dart';

/// Ekran szczegółów zadania – otwierany po kliknięciu karty na liście.
class TaskDetailsPage extends ConsumerStatefulWidget {
  const TaskDetailsPage({
    super.key,
    required this.task,
    this.categoryColorHex,
  });

  final TaskRow task;
  final String? categoryColorHex;

  @override
  ConsumerState<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends ConsumerState<TaskDetailsPage> {
  late TaskRow _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    final colorHex = widget.categoryColorHex ?? _task.colorHex;
    final baseColor = CategoryColors.parse(colorHex);
    final accentColor = _accentColor(baseColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły zadania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edytuj nazwę',
            onPressed: () => _handleEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Usuń zadanie',
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderSection(
            taskName: _task.name,
            createdAtMs: _task.createdAt,
            accentColor: accentColor,
          ),
          const SizedBox(height: 20),
          const _StatisticsSection(),
          const SizedBox(height: 20),
          _ActionsSection(
            onEdit: () => _handleEdit(context),
            onDelete: () => _handleDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => EditTaskDialogContent(task: _task),
    );
    if (newName == null || newName.trim().isEmpty || !mounted) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await ref.read(tasksDaoProvider).renameTask(
          _task.id,
          name: newName.trim(),
          nowMs: nowMs,
        );

    if (!mounted) return;
    setState(() {
      _task = _task.copyWith(name: newName.trim(), updatedAt: nowMs);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nazwa zadania zapisana')),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed != true || !mounted) return;

    final tasksDao = ref.read(tasksDaoProvider);
    final sessionsDao = ref.read(sessionsDaoProvider);
    await sessionsDao.deleteSessionsByTaskId(_task.id);
    await tasksDao.deleteTask(_task.id);

    if (!mounted) return;
    ref.invalidate(calendarSessionsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zadanie usunięte')),
    );
    Navigator.of(context).pop();
  }

  static Color _accentColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withSaturation((hsl.saturation * 0.6).clamp(0.0, 1.0)).toColor();
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.taskName,
    required this.createdAtMs,
    required this.accentColor,
  });

  final String taskName;
  final int createdAtMs;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 10, top: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  taskName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              DateTimeUtils.formatTaskDateTimeFromEpochMs(createdAtMs),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statystyki',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wkrótce: czas trwania, historia sesji, streak, wykresy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Akcje',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edytuj'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Usuń'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
