import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import 'package:checkyourtime/core/utils/datetime_utils.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/task_notes_provider.dart';
import '../tasks_providers.dart';

/// Ekran szczegółów zadania – MVP w stylu iOS (czysty, rozwijane sekcje).
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
  late TextEditingController _titleController;
  bool _notesExpanded = false;
  bool _statsExpanded = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController = TextEditingController(text: widget.task.name);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitleIfChanged() async {
    final name = _titleController.text.trim();
    if (name.isEmpty || name == _task.name) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await ref.read(tasksDaoProvider).renameTask(_task.id, name: name, nowMs: nowMs);
    if (!mounted) return;
    setState(() => _task = _task.copyWith(name: name, updatedAt: nowMs));
  }

  @override
  Widget build(BuildContext context) {
    final colorHex = widget.categoryColorHex ?? _task.colorHex;
    final baseColor = CategoryColors.parse(colorHex);
    final category = _task.categoryId != null
        ? ref.watch(categoryByIdProvider(_task.categoryId!))
        : null;
    final categoryName = category?.name ?? 'Brak kategorii';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły zadania'),
        actions: [
          TextButton(
            onPressed: () async {
              await _saveTitleIfChanged();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Gotowe'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Usuń zadanie',
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MainInfoSection(
              titleController: _titleController,
              categoryName: categoryName,
              categoryColorHex: colorHex,
              isArchived: _task.isArchived,
              onTitleSubmitted: _saveTitleIfChanged,
            ),
            const SizedBox(height: 24),
            _CzasSection(task: _task),
            const SizedBox(height: 24),
            _TilesSection(
              taskId: _task.id,
              notesExpanded: _notesExpanded,
              statsExpanded: _statsExpanded,
              onToggleNotes: () => setState(() => _notesExpanded = !_notesExpanded),
              onToggleStats: () => setState(() => _statsExpanded = !_statsExpanded),
            ),
          ],
        ),
      ),
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
}

class _MainInfoSection extends StatelessWidget {
  const _MainInfoSection({
    required this.titleController,
    required this.categoryName,
    required this.categoryColorHex,
    required this.isArchived,
    required this.onTitleSubmitted,
  });

  final TextEditingController titleController;
  final String categoryName;
  final String? categoryColorHex;
  final bool isArchived;
  final VoidCallback onTitleSubmitted;

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.parse(categoryColorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: titleController,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Nazwa zadania',
          ),
          onSubmitted: (_) => onTitleSubmitted(),
          onEditingComplete: onTitleSubmitted,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isArchived ? 'zrobione' : 'w trakcie',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CzasSection extends StatelessWidget {
  const _CzasSection({required this.task});

  final TaskRow task;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(task.createdAt);
    final plannedMinutes = task.plannedTimeSec ~/ 60;
    final endTime = createdAt.add(Duration(minutes: plannedMinutes));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Czas',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          _RowLabelValue(label: 'Data', value: DateTimeUtils.formatDateFromEpochMs(task.createdAt)),
          const SizedBox(height: 8),
          _RowLabelValue(label: 'Godzina rozpoczęcia', value: DateTimeUtils.formatTimeFromEpochMs(task.createdAt)),
          const SizedBox(height: 8),
          _RowLabelValue(label: 'Długość zadania', value: '$plannedMinutes min'),
          const SizedBox(height: 8),
          _RowLabelValue(
            label: 'Godzina zakończenia',
            value: DateTimeUtils.formatTime(endTime),
          ),
        ],
      ),
    );
  }
}

class _RowLabelValue extends StatelessWidget {
  const _RowLabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _TilesSection extends ConsumerWidget {
  const _TilesSection({
    required this.taskId,
    required this.notesExpanded,
    required this.statsExpanded,
    required this.onToggleNotes,
    required this.onToggleStats,
  });

  final String taskId;
  final bool notesExpanded;
  final bool statsExpanded;
  final VoidCallback onToggleNotes;
  final VoidCallback onToggleStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TileCard(
                icon: Icons.note_outlined,
                label: 'Notatki',
                onTap: onToggleNotes,
                isExpanded: notesExpanded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TileCard(
                icon: Icons.bar_chart_outlined,
                label: 'Statystyki',
                onTap: onToggleStats,
                isExpanded: statsExpanded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: notesExpanded
              ? _NotesExpandedContent(taskId: taskId)
              : const SizedBox.shrink(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: statsExpanded
              ? _StatsExpandedContent(taskId: taskId)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isExpanded,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesExpandedContent extends ConsumerWidget {
  const _NotesExpandedContent({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(taskNotesListProvider(taskId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...notes.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateTimeUtils.formatTaskDateTimeFromEpochMs(n.createdAtMs),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddNoteDialog(context, ref, taskId),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Dodaj notatkę'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  static void _showAddNoteDialog(BuildContext context, WidgetRef ref, String taskId) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddNoteDialogContent(
        taskId: taskId,
        messenger: messenger,
        onSave: (content) {
          ref.read(taskNotesProvider.notifier).addNote(taskId, content);
        },
      ),
    );
  }
}

/// Dialog dodawania notatki – controller tylko w State, bezpieczny lifecycle.
class _AddNoteDialogContent extends StatefulWidget {
  const _AddNoteDialogContent({
    required this.taskId,
    required this.messenger,
    required this.onSave,
  });

  final String taskId;
  final ScaffoldMessengerState messenger;
  final void Function(String content) onSave;

  @override
  State<_AddNoteDialogContent> createState() => _AddNoteDialogContentState();
}

class _AddNoteDialogContentState extends State<_AddNoteDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAnuluj() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  void _onZapisz() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    widget.onSave(content);
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Notatka dodana')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nowa notatka'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Treść notatki…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _onAnuluj,
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _onZapisz,
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}

class _StatsExpandedContent extends ConsumerWidget {
  const _StatsExpandedContent({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksDao = ref.read(tasksDaoProvider);
    final sessionsDao = ref.read(sessionsDaoProvider);
    final sessionsStream = sessionsDao.watchSessionsByTaskId(taskId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
        ),
      ),
      child: FutureBuilder<TaskRow?>(
        future: tasksDao.getById(taskId),
        builder: (context, taskSnapshot) {
          return StreamBuilder<List<SessionRow>>(
            stream: sessionsStream,
            builder: (context, sessionsSnapshot) {
              final t = taskSnapshot.data;
              final sessions = sessionsSnapshot.data ?? [];
              final plannedSec = t?.plannedTimeSec ?? 0;
              final actualSec = sessions.fold<int>(0, (sum, s) => sum + s.durationSec);
              final hasData = plannedSec > 0 || actualSec > 0;

              if (!hasData) {
                return Text(
                  'Brak danych jeszcze',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowLabelValue(
                    label: 'Planowany czas',
                    value: '${plannedSec ~/ 60} min',
                  ),
                  const SizedBox(height: 8),
                  _RowLabelValue(
                    label: 'Rzeczywisty czas',
                    value: '${actualSec ~/ 60} min',
                  ),
                  const SizedBox(height: 8),
                  _RowLabelValue(
                    label: 'Liczba przerw',
                    value: '—',
                  ),
                  const SizedBox(height: 8),
                  _RowLabelValue(
                    label: 'Łączny czas przerw',
                    value: '—',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
