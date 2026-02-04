import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_db.dart';
import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';

class TimerState {
  const TimerState({
    required this.isRunning,
    required this.elapsed,
    this.activeSessionId,
    this.activeTaskId,
    this.startedAt,
  });

  final bool isRunning;
  final Duration elapsed;

  final String? activeSessionId;
  final String? activeTaskId;
  final DateTime? startedAt;

  TimerState copyWith({
    bool? isRunning,
    Duration? elapsed,
    String? activeSessionId,
    String? activeTaskId,
    DateTime? startedAt,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      elapsed: elapsed ?? this.elapsed,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  static const initial = TimerState(isRunning: false, elapsed: Duration.zero);
}

/// Wynik zatrzymania sesji – do dialogu nazwy zadania.
class StopResult {
  const StopResult({required this.taskId, required this.duration});
  final String taskId;
  final Duration duration;
}

final timerControllerProvider =
    NotifierProvider.autoDispose<TimerController, TimerState>(TimerController.new);

class TimerController extends AutoDisposeNotifier<TimerState> {
  Timer? _ticker;
  late Stopwatch _stopwatch;
  bool _disposed = false;

  @override
  TimerState build() {
    _stopwatch = Stopwatch();
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _ticker?.cancel();
      _ticker = null;
    });
    return TimerState.initial;
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  CategoriesDao get _categoriesDao => ref.read(categoriesDaoProvider);
  TasksDao get _tasksDao => ref.read(tasksDaoProvider);
  SessionsDao get _sessionsDao => ref.read(sessionsDaoProvider);

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _startTicker() {
    _cancelTicker();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_disposed || !state.isRunning) return;
      state = state.copyWith(elapsed: _stopwatch.elapsed);
    });
  }

  /// Start odliczania dla danej kategorii (po id). Tworzy task z nazwą "NazwaKategorii YYYY-MM-DD".
  Future<void> startWithCategory(String categoryId) async {
    if (state.isRunning) return;

    final category = await _categoriesDao.getById(categoryId);
    if (category == null) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final dateStr = _formatDate(now);
    final taskName = '${category.name} $dateStr';
    final taskId = _newId();
    final sessionId = _newId();

    await _tasksDao.upsertTask(
      TasksTableCompanion.insert(
        id: taskId,
        name: taskName,
        createdAt: nowMs,
        updatedAt: nowMs,
        categoryId: Value(categoryId),
      ),
    );

    await _sessionsDao.startSession(
      sessionId: sessionId,
      taskId: taskId,
      note: null,
      startAtMs: nowMs,
      nowMs: nowMs,
    );

    if (_disposed) return;

    _stopwatch
      ..reset()
      ..start();
    _startTicker();

    if (_disposed) return;
    state = state.copyWith(
      isRunning: true,
      elapsed: Duration.zero,
      activeSessionId: sessionId,
      activeTaskId: taskId,
      startedAt: now,
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Tworzy nową kategorię w tabeli categories. Zwraca id kategorii.
  Future<String> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final categoryId = _newId();
    await _categoriesDao.insertCategory(
      CategoriesTableCompanion.insert(
        id: categoryId,
        name: trimmed,
        createdAt: nowMs,
      ),
    );
    return categoryId;
  }

  Future<void> pause() async {
    if (!state.isRunning) return;
    _stopwatch.stop();
    _cancelTicker();
    if (_disposed) return;
    state = state.copyWith(isRunning: false);
  }

  Future<void> resume() async {
    if (state.isRunning) return;
    if (state.activeSessionId == null) return;
    if (_disposed) return;
    _stopwatch.start();
    _startTicker();
    state = state.copyWith(isRunning: true);
  }

  /// Zatrzymuje sesję w DB. Zwraca [StopResult] z taskId i duration do dialogu nazwy (lub null gdy brak sesji).
  Future<StopResult?> stop() async {
    final sessionId = state.activeSessionId;
    final taskId = state.activeTaskId;

    if (sessionId == null || taskId == null) return null;

    final duration = _stopwatch.elapsed;
    _stopwatch.stop();
    _cancelTicker();

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final task = await _tasksDao.getById(taskId);
    if (task != null && task.categoryId != null) {
      final baseName = task.name;
      final categoryId = task.categoryId!;
      final count = await _tasksDao.countByCategoryIdAndNamePrefix(categoryId, baseName);
      if (count > 1) {
        final newName = '$baseName [#${count - 1}]';
        await _tasksDao.renameTask(taskId, name: newName, nowMs: nowMs);
      }
    }

    await _sessionsDao.stopSession(
      sessionId: sessionId,
      endAtMs: nowMs,
      nowMs: nowMs,
    );

    if (_disposed) return null;
    state = TimerState.initial;
    return StopResult(taskId: taskId, duration: duration);
  }

  /// Zmienia nazwę zadania (np. z ekranu edycji).
  Future<void> setTaskName({
    required String taskId,
    required String name,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _tasksDao.renameTask(taskId, name: name, nowMs: nowMs);
  }
}
