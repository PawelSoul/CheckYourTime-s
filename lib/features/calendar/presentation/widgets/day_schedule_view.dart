import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../../../data/db/daos/sessions_dao.dart';
import '../../../tasks/tasks_providers.dart';
import '../../application/calendar_providers.dart';
import '../../domain/calendar_models.dart';
import 'grouped_by_category_view.dart';
import 'schedule_list_mode_selector.dart';
import 'timeline_view.dart';

class DayScheduleView extends ConsumerWidget {
  const DayScheduleView({
    super.key,
    required this.day,
    required this.sessionsInMonth,
  });

  final DateTime day;
  final List<SessionWithTask> sessionsInMonth;

  static List<SessionWithTask> _sessionsForDay(
    DateTime day,
    List<SessionWithTask> sessions,
  ) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final fromMs = startOfDay.millisecondsSinceEpoch;
    final toMs = endOfDay.millisecondsSinceEpoch;
    return sessions
        .where((s) => s.session.startAt >= fromMs && s.session.startAt < toMs)
        .toList();
  }

  static List<TimelineItemVm> _buildTimelineItems(
    List<SessionWithTask> sessions,
    String? Function(String categoryId) categoryColorHex,
  ) {
    final sorted = List<SessionWithTask>.from(sessions)
      ..sort((a, b) => a.session.startAt.compareTo(b.session.startAt));
    return sorted.map((s) {
      final task = s.task;
      final session = s.session;
      final hex = task.categoryId != null
          ? (categoryColorHex(task.categoryId!) ?? task.colorHex)
          : task.colorHex;
      final startAt = DateTime.fromMillisecondsSinceEpoch(session.startAt);
      final endAt = session.endAt != null
          ? DateTime.fromMillisecondsSinceEpoch(session.endAt!)
          : null;
      return TimelineItemVm(
        startAt: startAt,
        endAt: endAt,
        title: task.name,
        categoryColor: CategoryColors.parse(hex),
        categoryName: null,
        durationSec: session.durationSec,
      );
    }).toList();
  }

  static List<CategoryGroupVm> _buildCategoryGroups(
    List<SessionWithTask> sessions,
    String? Function(String categoryId) categoryName,
    String? Function(String categoryId) categoryColorHex,
  ) {
    final byCategory = <String, List<SessionWithTask>>{};
    for (final s in sessions) {
      final key = s.task.categoryId ?? '';
      byCategory.putIfAbsent(key, () => []).add(s);
    }
    for (final list in byCategory.values) {
      list.sort((a, b) => a.session.startAt.compareTo(b.session.startAt));
    }
    final groups = <CategoryGroupVm>[];
    for (final entry in byCategory.entries) {
      final categoryId = entry.key;
      final list = entry.value;
      final name = categoryId.isEmpty
          ? 'Bez kategorii'
          : (categoryName(categoryId) ?? 'Usunięta kategoria');
      final hex = categoryId.isEmpty
          ? null
          : (categoryColorHex(categoryId) ?? '#9CA3AF');
      final totalMinutes =
          list.fold<int>(0, (sum, s) => sum + (s.session.durationSec ~/ 60));
      final items = _buildTimelineItems(
        list,
        (id) => id.isEmpty ? null : categoryColorHex(id),
      );
      groups.add(CategoryGroupVm(
        categoryId: categoryId.isEmpty ? null : categoryId,
        categoryName: name,
        categoryColor: CategoryColors.parse(hex),
        totalMinutes: totalMinutes,
        items: items,
      ));
    }
    groups.sort((a, b) => a.categoryName.compareTo(b.categoryName));
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = _sessionsForDay(day, sessionsInMonth);
    final dayStr =
        '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];

    String? categoryName(String id) {
      try {
        return categories.firstWhere((c) => c.id == id).name;
      } catch (_) {
        return null;
      }
    }

    String? categoryColorHex(String id) {
      try {
        return categories.firstWhere((c) => c.id == id).colorHex;
      } catch (_) {
        return null;
      }
    }

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Brak sesji w dniu $dayStr',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final timelineItems = _buildTimelineItems(sessions, categoryColorHex);
    final categoryGroups =
        _buildCategoryGroups(sessions, categoryName, categoryColorHex);
    final mode = ref.watch(scheduleListModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Sesje – $dayStr',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        const ScheduleListModeSelector(),
        if (mode == ScheduleListMode.timeline)
          TimelineView(items: timelineItems)
        else
          GroupedByCategoryView(groups: categoryGroups),
      ],
    );
  }
}
