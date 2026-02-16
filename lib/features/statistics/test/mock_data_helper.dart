import 'package:checkyourtime/data/db/daos/categories_dao.dart';
import 'package:checkyourtime/data/db/daos/sessions_dao.dart';
import 'package:checkyourtime/data/db/daos/tasks_dao.dart';
import 'package:checkyourtime/data/db/tables/categories_table.dart';
import 'package:checkyourtime/data/db/tables/sessions_table.dart';
import 'package:checkyourtime/data/db/tables/tasks_table.dart';
import 'package:drift/drift.dart';

/// Helper do tworzenia przykładowych danych testowych dla statystyk.
/// 
/// Użycie w dev/test:
/// ```dart
/// final helper = MockDataHelper(
///   categoriesDao: ref.read(categoriesDaoProvider),
///   tasksDao: ref.read(tasksDaoProvider),
///   sessionsDao: ref.read(sessionsDaoProvider),
/// );
/// await helper.createMockDataForCategory('category-id');
/// ```
class MockDataHelper {
  MockDataHelper({
    required CategoriesDao categoriesDao,
    required TasksDao tasksDao,
    required SessionsDao sessionsDao,
  })  : _categoriesDao = categoriesDao,
        _tasksDao = tasksDao,
        _sessionsDao = sessionsDao;

  final CategoriesDao _categoriesDao;
  final TasksDao _tasksDao;
  final SessionsDao _sessionsDao;

  /// Tworzy przykładowe dane dla kategorii (ostatnie 30 dni z różnymi wzorcami).
  Future<void> createMockDataForCategory(String categoryId) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Utwórz kategorię jeśli nie istnieje
    try {
      await _categoriesDao.upsertCategory(
        CategoriesTableCompanion.insert(
          id: categoryId,
          name: 'Test Kategoria',
          colorHex: '#4F46E5',
          createdAt: nowMs,
        ),
      );
    } catch (_) {
      // Kategoria już istnieje
    }

    // Utwórz kilka zadań w kategorii
    final taskIds = <String>[];
    for (var i = 0; i < 3; i++) {
      final taskId = 'task-$categoryId-$i';
      taskIds.add(taskId);
      await _tasksDao.upsertTask(
        TasksTableCompanion.insert(
          id: taskId,
          name: 'Zadanie $i',
          categoryId: Value(categoryId),
          createdAt: nowMs - (i * 1000),
          updatedAt: nowMs - (i * 1000),
        ),
      );
    }

    // Utwórz sesje dla ostatnich 30 dni
    for (var dayOffset = 0; dayOffset < 30; dayOffset++) {
      final date = now.subtract(Duration(days: dayOffset));
      final dayStart = DateTime(date.year, date.month, date.day);

      // Różne wzorce:
      // - Dni parzyste: 2-3 sesje, 15-30 min każda
      // - Dni nieparzyste: 1 sesja, 5-10 min
      // - Co 7 dni: więcej sesji (4-5), więcej czasu
      final isEvenDay = dayOffset % 2 == 0;
      final isWeeklyPeak = dayOffset % 7 == 0;
      final sessionCount = isWeeklyPeak ? 5 : (isEvenDay ? 3 : 1);

      for (var s = 0; s < sessionCount; s++) {
        final sessionStart = dayStart.add(Duration(
          hours: 9 + s * 2, // 9:00, 11:00, 13:00...
          minutes: s * 15,
        ));
        final durationMinutes = isWeeklyPeak
            ? 30 + (s * 5)
            : (isEvenDay ? 20 + (s * 5) : 8);
        final sessionEnd = sessionStart.add(Duration(minutes: durationMinutes));

        final taskId = taskIds[dayOffset % taskIds.length];
        final sessionId = 'session-$categoryId-$dayOffset-$s';

        await _sessionsDao.upsertSession(
          SessionsTableCompanion.insert(
            id: sessionId,
            taskId: taskId,
            startAt: sessionStart.millisecondsSinceEpoch,
            endAt: Value(sessionEnd.millisecondsSinceEpoch),
            durationSec: Value(durationMinutes * 60),
            createdAt: sessionStart.millisecondsSinceEpoch,
            updatedAt: sessionEnd.millisecondsSinceEpoch,
          ),
        );
      }
    }
  }

  /// Tworzy dane dla wielu kategorii (do testowania rankingu).
  Future<void> createMockDataForMultipleCategories() async {
    final categories = ['cat-1', 'cat-2', 'cat-3'];
    for (final catId in categories) {
      await createMockDataForCategory(catId);
    }
  }

  /// Tworzy dane ze streak (kilka dni z rzędu spełniających warunki).
  Future<void> createMockStreakData(String categoryId, int streakDays) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Utwórz kategorię i zadanie
    try {
      await _categoriesDao.upsertCategory(
        CategoriesTableCompanion.insert(
          id: categoryId,
          name: 'Streak Test',
          colorHex: '#059669',
          createdAt: nowMs,
        ),
      );
    } catch (_) {}

    final taskId = 'task-$categoryId-streak';
    await _tasksDao.upsertTask(
      TasksTableCompanion.insert(
        id: taskId,
        name: 'Streak Task',
        categoryId: Value(categoryId),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );

    // Utwórz streak dni (minimum 2 sesje, >=10 min każdy dzień)
    for (var dayOffset = 0; dayOffset < streakDays; dayOffset++) {
      final date = now.subtract(Duration(days: dayOffset));
      final dayStart = DateTime(date.year, date.month, date.day);

      // 2 sesje po 15 minut każda (razem 30 min >= 10)
      for (var s = 0; s < 2; s++) {
        final sessionStart = dayStart.add(Duration(hours: 10 + s * 3));
        final sessionEnd = sessionStart.add(const Duration(minutes: 15));

        await _sessionsDao.upsertSession(
          SessionsTableCompanion.insert(
            id: 'streak-$categoryId-$dayOffset-$s',
            taskId: taskId,
            startAt: sessionStart.millisecondsSinceEpoch,
            endAt: Value(sessionEnd.millisecondsSinceEpoch),
            durationSec: const Value(15 * 60),
            createdAt: sessionStart.millisecondsSinceEpoch,
            updatedAt: sessionEnd.millisecondsSinceEpoch,
          ),
        );
      }
    }
  }
}
