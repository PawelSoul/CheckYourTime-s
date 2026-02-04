import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/daos/tasks_dao.dart';
import '../../../tasks/tasks_providers.dart';
import '../../application/timer_controller.dart';

/// Bottom sheet: wybór zadania z kategorii lub utworzenie nowej kategorii.
/// Po wyborze / utworzeniu uruchamia stoper.
/// [onTaskSelected] – wywołane po starcie (np. nawigacja na /timer).
void showStartTaskSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onTaskSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => _StartTaskSheetContent(
        scrollController: scrollController,
        onTaskSelected: onTaskSelected ?? () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

class _StartTaskSheetContent extends ConsumerWidget {
  const _StartTaskSheetContent({
    required this.scrollController,
    required this.onTaskSelected,
  });

  final ScrollController scrollController;
  final VoidCallback onTaskSelected;

  static const _categoryNone = 'Inne';

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final timerNotifier = ref.read(timerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Wybierz zadanie lub dodaj nową kategorię',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              final byTag = <String?, List<TaskRow>>{};
              for (final t in tasks) {
                final tag = t.tag?.trim().isEmpty ?? true ? null : t.tag;
                byTag.putIfAbsent(tag, () => []).add(t);
              }
              final tagOrder = byTag.keys.toList()
                ..sort((a, b) => (a ?? _categoryNone).compareTo(b ?? _categoryNone));

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final tag in tagOrder) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        tag ?? _categoryNone,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                    for (final task in byTag[tag]!) ...[
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _parseColor(task.colorHex),
                          child: Text(
                            task.name.isNotEmpty ? task.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(task.name),
                        onTap: () async {
                          await timerNotifier.startWithTask(task.id);
                          if (!context.mounted) return;
                          onTaskSelected();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ],
                  const Divider(height: 24),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                    title: const Text('Nowa kategoria'),
                    subtitle: const Text('Dodaj nowe zadanie i zacznij odliczanie'),
                    onTap: () => _showNewCategoryForm(context, ref, timerNotifier),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showNewCategoryForm(
    BuildContext mainSheetContext,
    WidgetRef ref,
    TimerController timerNotifier,
  ) {
    final nameController = TextEditingController();
    showModalBottomSheet<void>(
      context: mainSheetContext,
      isScrollControlled: true,
      builder: (formContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(formContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nowa kategoria',
                  style: Theme.of(formContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa (np. Siłownia, Nauka)',
                    hintText: 'Wpisz nazwę',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => _submitNewCategory(
                    formContext,
                    mainSheetContext,
                    value.trim(),
                    timerNotifier,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _submitNewCategory(
                    formContext,
                    mainSheetContext,
                    nameController.text.trim(),
                    timerNotifier,
                  ),
                  child: const Text('Dodaj i start'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(formContext).pop(),
                  child: const Text('Anuluj'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => nameController.dispose());
  }

  Future<void> _submitNewCategory(
    BuildContext formContext,
    BuildContext mainSheetContext,
    String name,
    TimerController timerNotifier,
  ) async {
    if (name.isEmpty) return;
    final taskId = await timerNotifier.createTask(name, tag: name);
    if (!formContext.mounted) return;
    Navigator.of(formContext).pop();
    await timerNotifier.startWithTask(taskId);
    if (!mainSheetContext.mounted) return;
    Navigator.of(mainSheetContext).pop();
  }
}
