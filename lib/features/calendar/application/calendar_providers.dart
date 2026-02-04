import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_db_provider.dart';
import '../../../data/db/daos/sessions_dao.dart';

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
