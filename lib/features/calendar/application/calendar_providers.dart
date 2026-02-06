import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../tasks/tasks_providers.dart';
import '../domain/calendar_models.dart';

/// Zwraca [fromMs, toMs) dla danego miesiąca (pierwszy dzień 00:00 do pierwszego dnia następnego miesiąca).
(int fromMs, int toMs) _monthRange(DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
}

/// Provider wybranego miesiąca (do nawigacji w kalendarzu).
final calendarMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Wybrany dzień (do widoku dnia).
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Sesje z zadaniami dla aktualnie wybranego miesiąca w kalendarzu (tylko zakończone).
final calendarSessionsProvider = StreamProvider.autoDispose<List<SessionWithTask>>((ref) {
  final sessionsDao = ref.watch(sessionsDaoProvider);
  final month = ref.watch(calendarMonthProvider);
  final (fromMs, toMs) = _monthRange(month);
  return sessionsDao.watchSessionsWithTasksInRange(fromMs: fromMs, toMs: toMs);
});

/// Tryb listy pod siatką: „Oś czasu” (chronologicznie) lub „Według kategorii”.
enum ScheduleListMode { timeline, byCategory }

final scheduleListModeProvider = StateProvider<ScheduleListMode>((ref) => ScheduleListMode.timeline);

/// Kropki na siatce: dateKey -> DayDotsVm (max 3 kolory wg kategorii). Reaguje na zmiany kategorii (kolory).
final calendarDayDotsProvider = Provider.autoDispose<Map<String, DayDotsVm>>((ref) {
  final sessionsAsync = ref.watch(calendarSessionsProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);

  final sessions = sessionsAsync.valueOrNull ?? [];
  final categories = categoriesAsync.valueOrNull ?? [];

  final Map<String, Set<String>> dayToCategoryIds = {};
  for (final s in sessions) {
    final key = dateKey(DateTime.fromMillisecondsSinceEpoch(s.session.startAt));
    dayToCategoryIds.putIfAbsent(key, () => {}).add(s.task.categoryId ?? '');
  }

  Color categoryColor(String id) {
    if (id.isEmpty) return CategoryColors.parse(null);
    try {
      final c = categories.firstWhere((c) => c.id == id);
      return CategoryColors.parse(c.colorHex);
    } catch (_) {
      return CategoryColors.parse(null);
    }
  }

  final result = <String, DayDotsVm>{};
  for (final entry in dayToCategoryIds.entries) {
    final ids = entry.value.toList();
    final colors = ids.take(3).map(categoryColor).toList();
    result[entry.key] = DayDotsVm(
      colors: colors,
      hasMore: ids.length > 3,
    );
  }
  return result;
});
