import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../timer/presentation/widgets/start_task_sheet.dart';
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
                          'Brak kategorii.\nKliknij Start stoper\ni dodaj nową.',
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
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = category.id,
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
                : _TasksOfCategory(categoryId: selectedCategory!),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStartTaskSheet(
          context,
          ref,
          onTaskSelected: () => context.go('/timer'),
        ),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start stoper'),
      ),
    );
  }
}

class _TasksOfCategory extends ConsumerWidget {
  const _TasksOfCategory({required this.categoryId});

  final String categoryId;

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
          itemBuilder: (context, index) => TaskListItem(task: tasks[index]),
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
