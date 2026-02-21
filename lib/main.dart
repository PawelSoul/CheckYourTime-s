import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/tasks/application/task_notes_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(taskNotesPrefsKey);
  final initialNotes = await compute(parseTaskNotesFromJson, json);

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        initialTaskNotesMapProvider.overrideWithValue(initialNotes),
      ],
      child: const App(),
    ),
  );
}
