import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../tasks_providers.dart';
import 'widgets/task_list_item.dart';

class TasksListPage extends ConsumerWidget {
  const TasksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_rounded),
            tooltip: 'Edytuj kategorie',
            onPressed: () => _showManageCategoriesSheet(context, ref),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lewa: lista kategorii
          Material(
            elevation: 0,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Brak kategorii.\nPrzejdź do Stoper,\nżeby dodać nową i zacząć odliczanie.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category.id;
                      return ListTile(
                        selected: isSelected,
                        leading: CircleAvatar(
                          radius: 18,
                          child: Text(
                            category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () =>
                            ref.read(selectedCategoryProvider.notifier).state = category.id,
                        onLongPress: () =>
                            _showCategoryOptionsSheet(context, ref, category),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ),
            ),
          ),
          // Prawa: taski wybranej kategorii
          Expanded(
            child: selectedCategory == null || selectedCategory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kliknij kategorię po lewej,\nżeby zobaczyć listę zadań.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : _TasksOfCategory(
                    categoryId: selectedCategory!,
                    scaffoldContext: context,
                    onEditTask: (task) => _showEditTaskDialog(context, ref, task),
                    onDeleteTask: (task) => _showDeleteTaskDialog(context, ref, task),
                  ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showManageCategoriesSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final categoriesAsync = ref.read(categoriesStreamProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Brak kategorii. Dodaj pierwszą w Stoperze.',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(
                    'Kategorie',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            category.name.isNotEmpty
                                ? category.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edytuj nazwę',
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _showEditCategoryDialog(context, ref, category);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(ctx).colorScheme.error,
                              ),
                              tooltip: 'Usuń kategorię',
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _confirmDeleteCategory(context, ref, category);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Błąd: $err', style: Theme.of(ctx).textTheme.bodyMedium),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showCategoryOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
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
                category.name,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edytuj nazwę kategorii'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
              title: Text(
                'Usuń kategorię',
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
      await _showEditCategoryDialog(context, ref, category);
    } else if (action == 'delete') {
      await _confirmDeleteCategory(context, ref, category);
    }
  }

  static Future<void> _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final categoriesDao = ref.read(categoriesDaoProvider);
    final controller = TextEditingController(text: category.name);
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nazwa kategorii'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nazwa',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) =>
                Navigator.of(ctx).pop(v.trim().isEmpty ? null : v),
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
        final categoryId = category.id;
        final nameToSave = name;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          final dao = ref.read(categoriesDaoProvider);
          await dao.renameCategory(categoryId, name: nameToSave);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategoria zapisana')),
          );
        });
      }
    } finally {
      controller.dispose();
    }
  }

  static Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć kategorię?'),
        content: const Text(
          'Zadania w tej kategorii pozostaną, ale bez przypisanej kategorii. Tej operacji nie można cofnąć.',
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

    if (confirmed != true || !context.mounted) return;

    final categoryId = category.id;
    final refCopy = ref;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final tasksDao = refCopy.read(tasksDaoProvider);
      final categoriesDao = refCopy.read(categoriesDaoProvider);
      await tasksDao.clearCategoryIdForCategory(categoryId);
      await categoriesDao.deleteCategory(categoryId);
      refCopy.read(selectedCategoryProvider.notifier).state = null;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategoria usunięta')),
      );
    });
  }

  static Future<void> _showEditTaskDialog(
    BuildContext context,
    WidgetRef ref,
    TaskRow task,
  ) async {
    final tasksDao = ref.read(tasksDaoProvider);
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
            onSubmitted: (v) =>
                Navigator.of(ctx).pop(v.trim().isEmpty ? null : v),
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
      if (name != null && name.isNotEmpty && context.mounted) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await tasksDao.renameTask(task.id, name: name, nowMs: nowMs);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nazwa zapisana')),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  static Future<void> _showDeleteTaskDialog(
    BuildContext context,
    WidgetRef ref,
    TaskRow task,
  ) async {
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

    if (confirmed != true || !context.mounted) return;

    final tasksDao = ref.read(tasksDaoProvider);
    final sessionsDao = ref.read(sessionsDaoProvider);
    await sessionsDao.deleteSessionsByTaskId(task.id);
    await tasksDao.deleteTask(task.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadanie usunięte')),
      );
    }
  }
}

class _TasksOfCategory extends ConsumerWidget {
  const _TasksOfCategory({
    required this.categoryId,
    required this.scaffoldContext,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final String categoryId;
  final BuildContext scaffoldContext;
  final void Function(TaskRow task) onEditTask;
  final void Function(TaskRow task) onDeleteTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksByCategoryProvider(categoryId));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'Brak zadań w tej kategorii.\nUruchom stoper i zatrzymaj go,\nżeby dodać pierwszy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskListItem(
            task: tasks[index],
            scaffoldContext: scaffoldContext,
            onEditTask: onEditTask,
            onDeleteTask: onDeleteTask,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

/// Wybrana kategoria (do pokazania tasków po prawej).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
