import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Jedna notatka powiązana z zadaniem (taskId). Placeholder – łatwo podmienić na DB.
class TaskNote {
  const TaskNote({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdAtMs,
  });

  final String id;
  final String taskId;
  final String content;
  final int createdAtMs;

  TaskNote copyWith({String? id, String? taskId, String? content, int? createdAtMs}) {
    return TaskNote(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      content: content ?? this.content,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }
}

/// In-memory storage: taskId -> lista notatek. Łatwo podmienić na repozytorium/DB.
class TaskNotesNotifier extends StateNotifier<Map<String, List<TaskNote>>> {
  TaskNotesNotifier() : super({});

  List<TaskNote> getNotes(String taskId) {
    final list = state[taskId];
    if (list == null) return [];
    return List.unmodifiable(list);
  }

  void addNote(String taskId, String content) {
    if (content.trim().isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final id = '${taskId}_${nowMs}';
    final note = TaskNote(id: id, taskId: taskId, content: content.trim(), createdAtMs: nowMs);
    final list = <TaskNote>[...(state[taskId] ?? []), note];
    state = {...state, taskId: list};
  }

  void removeNote(String taskId, String noteId) {
    final list = state[taskId];
    if (list == null) return;
    final next = list.where((n) => n.id != noteId).toList();
    if (next.isEmpty) {
      final m = Map<String, List<TaskNote>>.from(state);
      m.remove(taskId);
      state = m;
    } else {
      state = {...state, taskId: next};
    }
  }
}

final taskNotesProvider =
    StateNotifierProvider<TaskNotesNotifier, Map<String, List<TaskNote>>>((ref) => TaskNotesNotifier());

/// Lista notatek dla danego zadania. Zwraca nową listę przy każdej zmianie, żeby UI się odświeżało.
final taskNotesListProvider = Provider.family<List<TaskNote>, String>((ref, taskId) {
  ref.watch(taskNotesProvider);
  return List<TaskNote>.from(ref.read(taskNotesProvider.notifier).getNotes(taskId));
});
