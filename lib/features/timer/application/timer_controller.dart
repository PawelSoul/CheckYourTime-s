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

  /// Start odliczania dla istniejącego zadania (wybranego z listy).
  Future<void> startWithTask(String taskId) async {
    if (state.isRunning) return;

    final existing = await _tasksDao.getById(taskId);
    if (existing == null) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final sessionId = _newId();

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

  /// Tworzy nowe zadanie (np. nowa kategoria) i zwraca jego id.
  Future<String> createTask(String name, {String? tag}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final taskId = _newId();
    await _tasksDao.upsertTask(
      TasksTableCompanion.insert(
        id: taskId,
        name: name,
        createdAt: nowMs,
        updatedAt: nowMs,
        tag: tag != null ? Value(tag) : const Value.absent(),
      ),
    );
    return taskId;
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

  /// Zatrzymuje sesję w DB i zwraca info potrzebne do dialogu z nazwą.
  Future<({String taskId, String sessionId, Duration duration})?> stop() async {
    final sessionId = state.activeSessionId;
    final taskId = state.activeTaskId;

    if (sessionId == null || taskId == null) return null;

    _stopwatch.stop();
    _ticker?.cancel();

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    await _sessionsDao.stopSession(
      sessionId: sessionId,
      endAtMs: nowMs,
      nowMs: nowMs,
    );

    final duration = _stopwatch.elapsed;

    state = TimerState.initial;

    return (taskId: taskId, sessionId: sessionId, duration: duration);
  }

  Future<void> setTaskName({
    required String taskId,
    required String name,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _tasksDao.renameTask(taskId, name: name, nowMs: nowMs);
  }
}
