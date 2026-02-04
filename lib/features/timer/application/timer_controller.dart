import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_db.dart';
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

final timerControllerProvider =
    NotifierProvider.autoDispose<TimerController, TimerState>(TimerController.new);

class TimerController extends AutoDisposeNotifier<TimerState> {
  Timer? _ticker;
  late final Stopwatch _stopwatch;

  @override
  TimerState build() {
    _stopwatch = Stopwatch();
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return TimerState.initial;
  }

  TasksDao get _tasksDao => ref.read(tasksDaoProvider);
  SessionsDao get _sessionsDao => ref.read(sessionsDaoProvider);

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      state = state.copyWith(elapsed: _stopwatch.elapsed);
    });
  }

  /// Start odliczania dla danej kategorii. Tworzy task z nazwą "Kategoria YYYY-MM-DD".
  Future<void> startWithCategory(String categoryName) async {
    if (state.isRunning) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final dateStr = _formatDate(now);
    final taskName = '$categoryName $dateStr';
    final taskId = _newId();
    final sessionId = _newId();

    await _tasksDao.upsertTask(
      TasksTableCompanion.insert(
        id: taskId,
        name: taskName,
        createdAt: nowMs,
        updatedAt: nowMs,
        tag: Value(categoryName),
      ),
    );

    await _sessionsDao.startSession(
      sessionId: sessionId,
      taskId: taskId,
      note: null,
      startAtMs: nowMs,
      nowMs: nowMs,
    );

    _stopwatch
      ..reset()
      ..start();
    _startTicker();

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

  /// Tworzy nową kategorię (task z name == tag). Zwraca nazwę kategorii.
  Future<String> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final taskId = _newId();
    await _tasksDao.upsertTask(
      TasksTableCompanion.insert(
        id: taskId,
        name: trimmed,
        createdAt: nowMs,
        updatedAt: nowMs,
        tag: Value(trimmed),
      ),
    );
    return trimmed;
  }

  Future<void> pause() async {
    if (!state.isRunning) return;
    _stopwatch.stop();
    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
  }

  Future<void> resume() async {
    if (state.isRunning) return;
    if (state.activeSessionId == null) return;
    _stopwatch.start();
    _startTicker();
    state = state.copyWith(isRunning: true);
  }

  /// Zatrzymuje sesję w DB. Nazwę taska uzupełnia o "[#n]" gdy w tej samej kategorii jest duplikat daty.
  Future<void> stop() async {
    final sessionId = state.activeSessionId;
    final taskId = state.activeTaskId;

    if (sessionId == null || taskId == null) return;

    _stopwatch.stop();
    _ticker?.cancel();

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final task = await _tasksDao.getById(taskId);
    if (task != null) {
      final baseName = task.name;
      final categoryTag = task.tag ?? '';
      final count = await _tasksDao.countByTagAndNamePrefix(categoryTag, baseName);
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

    state = TimerState.initial;
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
