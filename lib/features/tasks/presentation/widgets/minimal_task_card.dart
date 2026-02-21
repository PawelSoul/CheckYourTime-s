import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/category_colors.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../data/db/daos/tasks_dao.dart';
import '../../tasks_providers.dart';
import '../task_details_page.dart';

/// Minimalistyczna karta zadania: tytuł + data + godziny rozpoczęcia/zakończenia.
/// Używa taskSessionSummaryProvider zamiast StreamBuilder – jedna subskrypcja Riverpod, brak tworzenia streamu w build().
class MinimalTaskCard extends ConsumerWidget {
  const MinimalTaskCard({
    super.key,
    required this.task,
    required this.categoryColorHex,
  });

  final TaskRow task;
  final String? categoryColorHex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = CategoryColors.parse(categoryColorHex ?? task.colorHex);
    final summaryAsync = ref.watch(taskSessionSummaryProvider(task.id));

    return summaryAsync.when(
      data: (summary) {
        final startTime = summary?.start ??
            DateTimeUtils.formatTimeFromEpochMs(task.createdAt);
        final endTime = summary?.end;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => TaskDetailsPage(
                    task: task,
                    categoryColorHex: categoryColorHex,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pierwszy wiersz: kropka + tytuł
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Drugi wiersz: data • godziny
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      _formatDateTime(startTime, endTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                    ),
                  ),
                  // Opcjonalna cienka linia akcentu na dole
                  const SizedBox(height: 8),
                  Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTaskDetails(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }

  void _openTaskDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailsPage(
          task: task,
          categoryColorHex: categoryColorHex,
        ),
      ),
    );
  }

  String _formatDateTime(String startTime, String? endTime) {
    final date = DateTimeUtils.formatDateFromEpochMs(task.createdAt);
    if (endTime != null) {
      return '$date • $startTime — $endTime';
    }
    return '$date • $startTime';
  }
}
