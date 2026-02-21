# Raport optymalizacji wydajności (Flutter)

Optymalizacje wprowadzone w celu zmniejszenia janku, przyspieszenia startu i ograniczenia zużycia pamięci. Zachowano identyczne zachowanie i UI.

---

## 1. Priorytet: Timer – mniej przebudów przy ticku (200 ms)

**Problem:** Cała `TimerPage` obserwowała `timerControllerProvider`. Co 200 ms zmieniało się `elapsed`, więc cała strona (Scaffold, AppBar, chip, kontrolki, overlay) przechodziła `build()` → jank i zbędna praca.

**Rozwiązanie:**
- Strona obserwuje tylko **meta** (bez `elapsed`) przez `ref.watch(timerControllerProvider.select(_meta))`, gdzie `_meta` zwraca `(activeSessionId, isRunning, activeCategoryId, activeTaskId)`.
- Sekcja **zegara i paska postępu** jest w osobnym `Consumer`, który obserwuje pełny `timerControllerProvider` – rebuilduje się tylko ten fragment.
- **Kontrolki** (`TimerControlLayer`) są w `_TimerControlLayerWithElapsed`: wewnątrz obserwowany jest tylko `elapsed` (`select((s) => s.elapsed)`), a reszta parametrów przekazywana z góry.

**Przed:**
```dart
final state = ref.watch(timerControllerProvider);
// ... cały build z state.elapsed, state.activeSessionId, itd.
return Scaffold(
  body: Stack(
    children: [
      Column(/* progress, clock, chip, glow – wszystko z state */),
      Positioned(child: TimerControlLayer(currentElapsed: state.elapsed, ...)),
    ],
  ),
);
```

**Po:**
```dart
final meta = ref.watch(timerControllerProvider.select(_meta)); // bez elapsed
// ...
Consumer(
  builder: (context, ref, _) {
    final state = ref.watch(timerControllerProvider);
    return Column(/* tylko progress + clock */);
  },
),
// ...
_TimerControlLayerWithElapsed(/* currentElapsed z wewnętrznego watch(elapsed) */),
```

**Efekt:** Przy działającym stoperze przebudowują się tylko: blok zegara + pasek postępu oraz warstwa kontrolek. Scaffold, AppBar, chip, glow i overlay nie rebuildują się co tick.

**DevTools:** Performance → Timeline, włącz „Show widget rebuilds”. Przy włączonym timerze powinny się podświetlać głównie wewnętrzny `Consumer` i `_TimerControlLayerWithElapsed`, a nie cała strona.

---

## 2. Priorytet: Start aplikacji – parsowanie JSON w isolate

**Problem:** `loadTaskNotesFromPrefs(prefs)` wywoływane w `main()` przed `runApp()`: `jsonDecode()` i budowa `Map<String, List<TaskNote>>` na wątku UI blokowały pierwsze klatki.

**Rozwiązanie:**
- Wydzielone parsowanie do funkcji top-level `parseTaskNotesFromJson(String? json)` (tylko argument typu `String?` – Sendable).
- W `main()`: odczyt surowego JSON z SharedPreferences (szybki), potem `await compute(parseTaskNotesFromJson, json)` – parsowanie w osobnym isolate.
- Klucz prefs wyeksponowany jako `taskNotesPrefsKey` (używany w main i w zapisie).

**Przed:**
```dart
final prefs = await SharedPreferences.getInstance();
final initialNotes = loadTaskNotesFromPrefs(prefs); // jsonDecode na UI
runApp(ProviderScope(overrides: [..., initialTaskNotesMapProvider.overrideWithValue(initialNotes)], ...));
```

**Po:**
```dart
final prefs = await SharedPreferences.getInstance();
final json = prefs.getString(taskNotesPrefsKey);
final initialNotes = await compute(parseTaskNotesFromJson, json);
runApp(...);
```

**Efekt:** Pierwsza klatka nie czeka na parsowanie; mniej ryzyka „białego ekranu” przy większej ilości notatek.

**DevTools:** Performance → CPU profile przy starcie; przed optymalizacją widać `jsonDecode` / `fromJson` na main isolate, po – brak tego na UI.

---

## 3. Priorytet: Lista zadań – brak StreamBuildera w build() i klucze w ListView

**Problem:**
- W `MinimalTaskCard.build()` wywoływane było `sessionsDao.watchSessionsByTaskId(task.id)` i przekazywane do `StreamBuilder` → przy każdym rebuildzie karty tworzona była nowa subskrypcja streamu (zbędne obciążenie i ryzyko wycieków).
- Lista zadań w `ListView.builder` nie miała kluczy → słabsze diffowanie i potencjalnie więcej przebudów przy zmianie listy.

**Rozwiązanie:**
- Dodany `taskSessionSummaryProvider` (StreamProvider.autoDispose.family) zwracający `({String start, String? end})?` na podstawie `sessionsDao.watchSessionsByTaskId(taskId)`.
- `MinimalTaskCard` używa `ref.watch(taskSessionSummaryProvider(task.id))` i `.when(data: ..., loading: ..., error: ...)` zamiast `StreamBuilder`.
- W `_TasksOfCategory`: `MinimalTaskCard(..., key: ValueKey(filtered[index].id), ...)`.

**Przed:**
```dart
final sessionsStream = sessionsDao.watchSessionsByTaskId(task.id);
return StreamBuilder<List<SessionRow>>(
  stream: sessionsStream,
  builder: (context, snapshot) { ... },
);
// ListView.builder bez key
itemBuilder: (context, index) => MinimalTaskCard(task: filtered[index], ...),
```

**Po:**
```dart
final summaryAsync = ref.watch(taskSessionSummaryProvider(task.id));
return summaryAsync.when(
  data: (summary) => Material(...),
  loading: () => ...,
  error: (_, __) => ...,
);
// ListView.builder z key
itemBuilder: (context, index) => MinimalTaskCard(
  key: ValueKey(filtered[index].id),
  task: filtered[index],
  ...,
),
```

**Efekt:** Jedna subskrypcja na zadanie, zarządzana przez Riverpod; brak tworzenia streamów w `build()`. Klucze poprawiają stabilność listy i diffowanie.

**DevTools:** Flutter Inspector → „Highlight repaints” / „Highlight rebuilds”; przy scrollu listy zadań mniej zbędnych przebudów; w Memory nie powinno przybywać subskrypcji streamów przy przewijaniu.

---

## 4. Priorytet: Notatki – przebudowy tylko dla zmienionej listy (taskId)

**Problem:** `taskNotesListProvider` robił `ref.watch(taskNotesProvider)` → zmiana notatki w jednym zadaniu powodowała przebudowę wszystkich konsumentów `taskNotesListProvider(taskId)` (np. lista notatek w szczegółach innego zadania).

**Rozwiązanie:** Watch zawężony do wpisu dla danego `taskId`:  
`ref.watch(taskNotesProvider.select((m) => m[taskId]))`.

**Przed:**
```dart
final taskNotesListProvider = Provider.family<List<TaskNote>, String>((ref, taskId) {
  ref.watch(taskNotesProvider);  // cała mapa
  return ref.read(taskNotesProvider.notifier).getNotes(taskId);
});
```

**Po:**
```dart
final taskNotesListProvider = Provider.family<List<TaskNote>, String>((ref, taskId) {
  ref.watch(taskNotesProvider.select((m) => m[taskId]));  // tylko ta lista
  return ref.read(taskNotesProvider.notifier).getNotes(taskId);
});
```

**Efekt:** Przebudowują się tylko widoki używające listy notatek dla tego konkretnego `taskId`, który się zmienił.

**DevTools:** Przy dodaniu notatki do jednego zadania sprawdzić, że nie rebuildują się inne ekrany/listy zależne od innych `taskId`.

---

## 5. Priorytet: Kalendarz – lazy lista sesji w grupie kategorii

**Problem:** W `GroupedByCategoryView` lista sesji w każdej grupie była budowana jako `Column(children: [for (var i = 0; i < items.length; i++) ...])` → wszystkie wiersze od razu w drzewie, nawet poza ekranem.

**Rozwiązanie:** Zastąpienie `Column` przez `ListView.separated(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), ...)` z `itemBuilder` i `separatorBuilder`.

**Przed:**
```dart
return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const SizedBox(height: _rowSpacing),
      _SessionRow(...),
    ],
  ],
);
```

**Po:**
```dart
return ListView.separated(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: items.length,
  separatorBuilder: (_, __) => const SizedBox(height: _rowSpacing),
  itemBuilder: (context, index) => _SessionRow(...),
);
```

**Efekt:** Tylko widoczne (i ewentualnie buforowane) wiersze są budowane; mniej widgetów przy długich dniach z wieloma sesjami.

**DevTools:** Przy dużym dniu w kalendarzu (wiele sesji) – mniej elementów w drzewie widgetów i niższe zużycie pamięci; płynniejszy scroll w trybie „Według kategorii”.

---

## Co mierzyć w Flutter DevTools

- **Performance (Timeline):** „Widget rebuilds” – sprawdzić, że przy ticku timera rebuildują się tylko zegar i kontrolki, a nie cała strona.
- **CPU:** Przy starcie – brak ciężkiego `jsonDecode` na main isolate; przy liście zadań – brak tworzenia nowych streamów w build.
- **Memory:** Brak narastającej liczby subskrypcji przy scrollu listy zadań; po wyjściu z ekranu – autoDispose czyści `taskSessionSummaryProvider`.
- **Frames:** Dążenie do stabilnych 60 FPS (lub 120 na urządzeniach z wyższą częstotliwością) na ekranie timera i przy scrollu list zadań/kalendarza.

---

## Zachowanie i API

- Nie zmieniono logiki biznesowej ani flow nawigacji.
- UI i teksty pozostają takie same.
- Publiczne API (np. `loadTaskNotesFromPrefs`, `taskNotesPrefsKey`) są zachowane lub rozszerzone w sposób wstecznie kompatybilny.
