import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String taskNotesPrefsKey = 'task_notes_list';

/// Parsuje JSON notatek w isolate (do użycia z compute() przy starcie).
Map<String, List<TaskNote>> parseTaskNotesFromJson(String? json) {
  try {
    if (json == null || json.isEmpty) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final loaded = <String, List<TaskNote>>{};
    for (final e in decoded.entries) {
      final list = (e.value as List<dynamic>)
          .map((o) => TaskNote.fromJson(o as Map<String, dynamic>))
          .toList();
      loaded[e.key as String] = list;
    }
    return loaded;
  } catch (_) {
    return {};
  }
}

/// Ładuje zapisane notatki z SharedPreferences (do użycia w main przed utworzeniem notifiera).
Map<String, List<TaskNote>> loadTaskNotesFromPrefs(SharedPreferences prefs) {
  return parseTaskNotesFromJson(prefs.getString(taskNotesPrefsKey));
}

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

/// Początkowy stan notatek (nadpisywany w main po wczytaniu z prefs – brak wyścigu z addNote).
final initialTaskNotesMapProvider = Provider<Map<String, List<TaskNote>>>((ref) => {});

/// Łączy dwie listy notatek (bez duplikatów po id), sortuje po createdAtMs.
List<TaskNote> _mergeNoteLists(List<TaskNote> a, List<TaskNote> b) {
  final byId = <String, TaskNote>{};
  for (final n in a) byId[n.id] = n;
  for (final n in b) byId[n.id] = n;
  final merged = byId.values.toList();
  merged.sort((x, y) => x.createdAtMs.compareTo(y.createdAtMs));
  return merged;
}

/// Zapisuje listę notatek i ładuje ją przy starcie. Każda dodana notatka trafia do listy i jest zapisywana.
class TaskNotesNotifier extends StateNotifier<Map<String, List<TaskNote>>> {
  TaskNotesNotifier(this._prefs, {Map<String, List<TaskNote>>? initialData})
      : super(initialData ?? {}) {
    if (initialData == null) _loadFromStorage();
  }

  final SharedPreferences _prefs;

  List<TaskNote> getNotes(String taskId) {
    final list = state[taskId];
    if (list == null) return [];
    return List<TaskNote>.from(list);
  }

  Future<void> _loadFromStorage() async {
    try {
      final loaded = loadTaskNotesFromPrefs(_prefs);
      if (loaded.isEmpty) return;
      final allTaskIds = {...loaded.keys, ...state.keys};
      final merged = <String, List<TaskNote>>{};
      for (final taskId in allTaskIds) {
        final fromLoaded = loaded[taskId] ?? [];
        final fromState = state[taskId] ?? [];
        merged[taskId] = _mergeNoteLists(fromLoaded, fromState);
      }
      state = merged;
    } catch (_) {
      // uszkodzone dane – zostaw aktualny stan
    }
  }

  Future<void> _saveToStorage() async {
    final encoded = <String, List<Map<String, dynamic>>>{};
    for (final e in state.entries) {
      encoded[e.key] = e.value.map((n) => n.toJson()).toList();
    }
    await _prefs.setString(taskNotesPrefsKey, jsonEncode(encoded));
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
  (ref) => TaskNotesNotifier(
    ref.watch(sharedPrefsProvider),
    initialData: ref.watch(initialTaskNotesMapProvider),
  ),
);

/// Lista notatek dla danego zadania – przebudowa tylko gdy zmieni się lista dla tego taskId.
final taskNotesListProvider =
    Provider.family<List<TaskNote>, String>((ref, taskId) {
  ref.watch(taskNotesProvider.select((m) => m[taskId]));
  return ref.read(taskNotesProvider.notifier).getNotes(taskId);
});
