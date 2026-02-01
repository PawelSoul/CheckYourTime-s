class ActiveSession {
  final String taskId;
  final String taskName;
  final DateTime startedAt;
  final Duration elapsed;
  final bool isRunning;

  const ActiveSession({
    required this.taskId,
    required this.taskName,
    required this.startedAt,
    required this.elapsed,
    required this.isRunning,
  });

  ActiveSession copyWith({
    String? taskId,
    String? taskName,
    DateTime? startedAt,
    Duration? elapsed,
    bool? isRunning,
  }) {
    return ActiveSession(
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      startedAt: startedAt ?? this.startedAt,
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
