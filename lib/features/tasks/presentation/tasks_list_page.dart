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
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadania'),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Brak zadań. Kliknij Start stoper i dodaj nową kategorię\nlub wybierz zadanie, żeby zacząć odliczanie.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) => TaskListItem(task: tasks[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
        ),
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
