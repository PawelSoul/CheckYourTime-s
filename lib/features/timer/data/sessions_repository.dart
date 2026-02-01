class CompletedSession {
  final String id;
  final String taskId;     // ✅ potrzebne do DB (FK)
  final String taskName;   // ✅ zostawiamy dla UI
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;

  CompletedSession({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
  });
}

abstract class SessionsRepository {
  Stream<List<CompletedSession>> watchAll();
  Future<void> add(CompletedSession session);
}
