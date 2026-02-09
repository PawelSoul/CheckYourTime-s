import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _taskNotesPrefsKey = 'task_notes_list';

/// Jedna notatka powiązana z zadaniem (taskId).
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'content': content,
        'createdAtMs': createdAtMs,
      };

  static TaskNote fromJson(Map<String, dynamic> json) => TaskNote(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        content: json['content'] as String,
        createdAtMs: json['createdAtMs'] as int,
      );

  TaskNote copyWith({
    String? id,
    String? taskId,
    String? content,
    int? createdAtMs,
  }) {
    return TaskNote(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      content: content ?? this.content,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }
}

/// Provider SharedPreferences (nadpisywany w main).
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPrefsProvider must be overridden in main with SharedPreferences.getInstance()',
  );
});

/// Zapisuje listę notatek i ładuje ją przy starcie. Każda dodana notatka trafia do listy i jest zapisywana.
class TaskNotesNotifier extends StateNotifier<Map<String, List<TaskNote>>> {
  TaskNotesNotifier(this._prefs) : super({}) {
    _loadFromStorage();
  }

  final SharedPreferences _prefs;

  List<TaskNote> getNotes(String taskId) {
    final list = state[taskId];
    if (list == null) return [];
    return List<TaskNote>.from(list);
  }

  Future<void> _loadFromStorage() async {
    try {
      final json = _prefs.getString(_taskNotesPrefsKey);
      if (json == null || json.isEmpty) return;
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final loaded = <String, List<TaskNote>>{};
      for (final e in decoded.entries) {
        final list = (e.value as List<dynamic>)
            .map((o) => TaskNote.fromJson(o as Map<String, dynamic>))
            .toList();
        loaded[e.key as String] = list;
      }
      // Nadpisz tylko gdy stan nadal pusty – inaczej _loadFromStorage()
      // mogłoby się skończyć po addNote() i zniszczyć świeżo dodane notatki.
      if (state.isEmpty) {
        state = loaded;
      }
    } catch (_) {
      // uszkodzone dane – zostaw puste
    }
  }

  Future<void> _saveToStorage() async {
    final encoded = <String, List<Map<String, dynamic>>>{};
    for (final e in state.entries) {
      encoded[e.key] = e.value.map((n) => n.toJson()).toList();
    }
    await _prefs.setString(_taskNotesPrefsKey, jsonEncode(encoded));
  }

  void addNote(String taskId, String content) {
    if (content.trim().isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final id = '${taskId}_$nowMs';
    final note = TaskNote(
      id: id,
      taskId: taskId,
      content: content.trim(),
      createdAtMs: nowMs,
    );
    final list = <TaskNote>[...getNotes(taskId), note];
    state = {...state, taskId: list};
    _saveToStorage();
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
    _saveToStorage();
  }
}

final taskNotesProvider =
    StateNotifierProvider<TaskNotesNotifier, Map<String, List<TaskNote>>>(
  (ref) => TaskNotesNotifier(ref.watch(sharedPrefsProvider)),
);

/// Lista notatek dla danego zadania (z zapisanej listy).
final taskNotesListProvider =
    Provider.family<List<TaskNote>, String>((ref, taskId) {
  ref.watch(taskNotesProvider);
  return ref.read(taskNotesProvider.notifier).getNotes(taskId);
});
