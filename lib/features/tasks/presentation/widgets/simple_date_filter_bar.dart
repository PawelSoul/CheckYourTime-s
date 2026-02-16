import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tasks_date_filter.dart';
import '../../tasks_providers.dart';

/// Uproszczony pasek filtra: tylko "Wszystkie" / "Ten miesiąc".
class SimpleDateFilterBar extends ConsumerWidget {
  const SimpleDateFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(tasksDateFilterProvider);
    final isThisMonth = _isThisMonth(filter);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Okres:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<TasksDateFilterKind>(
            segments: const [
              ButtonSegment(
                value: TasksDateFilterKind.all,
                label: Text('Wszystkie'),
              ),
              ButtonSegment(
                value: TasksDateFilterKind.month,
                label: Text('Ten miesiąc'),
              ),
            ],
            selected: {isThisMonth ? TasksDateFilterKind.month : TasksDateFilterKind.all},
            onSelectionChanged: (Set<TasksDateFilterKind> selection) {
              if (selection.isNotEmpty) {
                final kind = selection.first;
                if (kind == TasksDateFilterKind.month) {
                  ref.read(tasksDateFilterProvider.notifier).state =
                      TasksDateFilterState.forMonth(now.year, now.month);
                } else {
                  ref.read(tasksDateFilterProvider.notifier).state = TasksDateFilterState.all;
                }
              }
            },
          ),
        ],
      ),
    );
  }

  bool _isThisMonth(TasksDateFilterState filter) {
    if (filter.kind != TasksDateFilterKind.month) return false;
    final now = DateTime.now();
    return filter.year == now.year && filter.month == now.month;
  }
}
