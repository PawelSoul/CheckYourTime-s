import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/category_colors.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../data/db/daos/sessions_dao.dart';
import '../../../../data/db/daos/tasks_dao.dart';
import '../../../../providers/app_db_provider.dart';
import '../task_details_page.dart';

/// Minimalistyczna karta zadania: tytuł + data + godziny rozpoczęcia/zakończenia.
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
    
    // Pobierz sesje dla zadania, żeby obliczyć godzinę rozpoczęcia i zakończenia
    final sessionsDao = ref.read(sessionsDaoProvider);
    final sessionsStream = sessionsDao.watchSessionsByTaskId(task.id);

    return StreamBuilder<List<SessionRow>>(
      stream: sessionsStream,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        
        // Znajdź pierwszą i ostatnią sesję
        SessionRow? firstSession;
        SessionRow? lastSession;
        if (sessions.isNotEmpty) {
          sessions.sort((a, b) => a.startAt.compareTo(b.startAt));
          firstSession = sessions.first;
          final completedSessions = sessions.where((s) => s.endAt != null).toList();
          if (completedSessions.isNotEmpty) {
            completedSessions.sort((a, b) => (b.endAt ?? 0).compareTo(a.endAt ?? 0));
            lastSession = completedSessions.first;
          }
        }

        final startTime = firstSession != null
            ? DateTimeUtils.formatTimeFromEpochMs(firstSession.startAt)
            : DateTimeUtils.formatTimeFromEpochMs(task.createdAt);
        final endTime = lastSession?.endAt != null
            ? DateTimeUtils.formatTimeFromEpochMs(lastSession!.endAt!)
            : null;

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
