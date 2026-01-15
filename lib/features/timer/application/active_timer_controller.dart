import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sessions_repository.dart';
import '../data/sessions_repository_impl.dart';
import '../domain/active_session.dart';

enum TimerStatus { idle, running, paused }

class ActiveTimerState {
  final TimerStatus status;
  final ActiveSession? session;

  const ActiveTimerState({
    required this.status,
    required this.session,
  });

  const ActiveTimerState.idle() : status = TimerStatus.idle, session = null;

  ActiveTimerState copyWith({
    TimerStatus? status,
    ActiveSession? session,
  }) {
    return ActiveTimerState(
      status: status ?? this.status,
      session: session ?? this.session,
    );
  }
}

/// Repository provider (później podmienisz na DB impl)
final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  final repo = InMemorySessionsRepository();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

final activeTimerControllerProvider =
    StateNotifierProvider<ActiveTimerController, ActiveTimerState>((ref) {
  return ActiveTimerController(ref.read);
});

class ActiveTimerController extends StateNotifier<ActiveTimerState> {
  ActiveTimerController(this._read) : super(const ActiveTimerState.idle());

  final Reader _read;

  Timer? _ticker;
  DateTime? _lastTickAt;

  void start({required String taskName}) {
    if (taskName.trim().isEmpty) return;

    _stopTicker();

    final now = DateTime.now();
    final session = ActiveSession(
      taskName: taskName.trim(),
      startedAt: now,
      elapsed: Duration.zero,
      isRunning: true,
    );

    state = ActiveTimerState(status: TimerStatus.running, session: session);

    _lastTickAt = now;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void pause() {
    if (state.status != TimerStatus.running || state.session == null) return;
    _stopTicker();

    final s = state.session!;
    state = state.copyWith(
      status: TimerStatus.paused,
      session: s.copyWith(isRunning: false),
    );
  }

  void resume() {
    if (state.status != TimerStatus.paused || state.session == null) return;

    final now = DateTime.now();
    _lastTickAt = now;

    final s = state.session!;
    state = state.copyWith(
      status: TimerStatus.running,
      session: s.copyWith(isRunning: true),
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> stopAndSave() async {
    if (state.session == null) return;

    final repo = _read(sessionsRepositoryProvider);

    _stopTicker();

    final s = state.session!;
    final endedAt = DateTime.now();

    final completed = CompletedSession(
      id: _newId(),
      taskName: s.taskName,
      startedAt: s.startedAt,
      endedAt: endedAt,
      duration: s.elapsed,
    );

    await repo.add(completed);

    state = const ActiveTimerState.idle();
  }

  void reset() {
    _stopTicker();
    state = const ActiveTimerState.idle();
  }

  void _onTick() {
    final current = state.session;
    if (current == null || state.status != TimerStatus.running) return;

    final now = DateTime.now();
    final last = _lastTickAt ?? now;
    _lastTickAt = now;

    final delta = now.difference(last);
    final nextElapsed = current.elapsed + delta;

    state = state.copyWith(
      session: current.copyWith(elapsed: nextElapsed, isRunning: true),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _lastTickAt = null;
  }

  String _newId() {
    // proste ID bez pakietów
    final ms = DateTime.now().microsecondsSinceEpoch;
    return 'sess_$ms';
    }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
