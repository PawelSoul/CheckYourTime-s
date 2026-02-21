import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../statistics/domain/models/statistics_models.dart';
import '../../statistics/presentation/category_stats_screen.dart';
import '../application/tasks_date_filter.dart';
import '../tasks_providers.dart';
import 'widgets/category_chips_bar.dart';
import 'widgets/minimal_task_card.dart';
import 'widgets/simple_date_filter_bar.dart';

class TasksListPage extends ConsumerWidget {
  const TasksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesSortedByUsageProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_rounded),
            tooltip: 'Edytuj kategorie',
            onPressed: () => _showManageCategoriesSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poziomy scroll kategorii (od najczęściej do najmniej używanej)
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Brak kategorii. Przejdź do Stoper, żeby dodać nową.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return CategoryChipsBar(
                categories: categories,
                selectedCategoryId: selectedCategory,
                onCategorySelected: (categoryId) =>
                    ref.read(selectedCategoryProvider.notifier).state = categoryId,
                onCategoryLongPress: (category) =>
                    _showCategoryOptionsSheet(context, ref, category),
              );
            },
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          // Pasek filtra okresu
          if (selectedCategory != null && selectedCategory.isNotEmpty)
            const SimpleDateFilterBar(),
          // Przycisk „Statystyki kategorii” (tylko gdy kategoria wybrana)
          if (selectedCategory != null && selectedCategory.isNotEmpty)
            _CategoryStatsButton(categoryId: selectedCategory),
          // Lista zadań
          Expanded(
            child: selectedCategory == null || selectedCategory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Wybierz kategorię powyżej,\nżeby zobaczyć listę zadań.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _TasksOfCategory(
                      key: ValueKey(selectedCategory),
                      categoryId: selectedCategory,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Otwiera dialog/sheet po zamknięciu obecnego bottom sheet (żeby overlay był poprawny).
  static void _openAfterSheetClosed(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() open,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await open();
    });
  }

  static Future<void> _showManageCategoriesSheet(
    BuildContext scaffoldContext,
    WidgetRef ref,
  ) async {
    final categoriesAsync = ref.read(categoriesStreamProvider);
    await showModalBottomSheet<void>(
      context: scaffoldContext,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Brak kategorii. Dodaj pierwszą w Stoperze.',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(
                    'Kategorie',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (_, index) {
                      final category = categories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CategoryColors.parse(category.colorHex),
                          child: Text(
                            category.name.isNotEmpty
                                ? category.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edytuj nazwę',
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _openAfterSheetClosed(scaffoldContext, ref, () async {
                                  await _showEditCategoryDialog(scaffoldContext, ref, category);
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.palette_outlined),
                              tooltip: 'Zmień kolor',
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _openAfterSheetClosed(scaffoldContext, ref, () async {
                                  await _showCategoryColorPicker(scaffoldContext, ref, category);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(ctx).colorScheme.error,
                              ),
                              tooltip: 'Usuń kategorię',
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _openAfterSheetClosed(scaffoldContext, ref, () async {
                                  await _confirmDeleteCategory(scaffoldContext, ref, category);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Błąd: $err', style: Theme.of(ctx).textTheme.bodyMedium),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showCategoryOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                category.name,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edytuj nazwę kategorii'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Zmień kolor'),
              onTap: () => Navigator.of(ctx).pop('color'),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
              title: Text(
                'Usuń kategorię',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      await _showEditCategoryDialog(context, ref, category);
    } else if (action == 'color') {
      await _showCategoryColorPicker(context, ref, category);
    } else if (action == 'delete') {
      await _confirmDeleteCategory(context, ref, category);
    }
  }

  static Future<void> _showCategoryColorPicker(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final categoriesDao = ref.read(categoriesDaoProvider);
    final tasksDao = ref.read(tasksDaoProvider);

    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 24 + MediaQuery.of(ctx).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kolor kategorii',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final hex in CategoryColors.hexPool)
                    _ColorPickerDot(
                      hex: hex,
                      isSelected: _hexEquals(hex, category.colorHex),
                      onTap: () => Navigator.of(ctx).pop(hex),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Anuluj'),
              ),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || chosen.trim().isEmpty || !context.mounted) return;
    final hexToSave = chosen.trim().startsWith('#') ? chosen.trim() : '#${chosen.trim()}';
    if (_hexEquals(hexToSave, category.colorHex)) return;

    final db = ref.read(appDbProvider);
    await db.transaction(() async {
      await categoriesDao.updateCategoryColor(category.id, hexToSave);
      await tasksDao.setColorForCategory(category.id, hexToSave);
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kolor kategorii zapisany')),
      );
    }
  }

  static bool _hexEquals(String a, String b) {
    final an = a.replaceFirst('#', '').trim().toUpperCase();
    final bn = b.replaceFirst('#', '').trim().toUpperCase();
    return an == bn;
  }

  static Future<void> _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditCategoryDialogContent(category: category),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await ref.read(categoriesDaoProvider).renameCategory(category.id, name: name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kategoria zapisana')),
    );
  }

  static Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć kategorię?'),
        content: Text(
          'Czy na pewno chcesz usunąć kategorię ${category.name}? '
          'Zostaną usunięte wszystkie wykonane zadania należące do tej kategorii.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final categoryId = category.id;
    final db = ref.read(appDbProvider);
    final tasksDao = ref.read(tasksDaoProvider);
    final sessionsDao = ref.read(sessionsDaoProvider);
    final categoriesDao = ref.read(categoriesDaoProvider);

    await db.transaction(() async {
      final completedIds = await tasksDao.getCompletedTaskIdsInCategory(categoryId);
      for (final taskId in completedIds) {
        await sessionsDao.deleteSessionsByTaskId(taskId);
        await tasksDao.deleteTask(taskId);
      }
      await tasksDao.clearCategoryIdForCategory(categoryId);
      await categoriesDao.deleteCategory(categoryId);
    });

    if (!context.mounted) return;
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.invalidate(calendarSessionsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kategoria usunięta')),
    );
  }

  static Future<void> _showDeleteTaskDialog(
    BuildContext context,
    WidgetRef ref,
    TaskRow task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć zadanie?'),
        content: const Text(
          'Zadanie i powiązane sesje zostaną trwale usunięte. Tej operacji nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final tasksDao = ref.read(tasksDaoProvider);
    final sessionsDao = ref.read(sessionsDaoProvider);
    await sessionsDao.deleteSessionsByTaskId(task.id);
    await tasksDao.deleteTask(task.id);

    if (context.mounted) {
      ref.invalidate(calendarSessionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadanie usunięte')),
      );
    }
  }
}

/// Pasek filtra czasowego nad listą zadań.
class _TasksDateFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(tasksDateFilterProvider);
    final label = _filterLabel(filter);

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              'Okres:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PopupMenuButton<TasksDateFilterKind>(
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
                onSelected: (kind) => _onFilterSelected(context, ref, kind),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: TasksDateFilterKind.all,
                    child: Text('Wszystkie'),
                  ),
                  const PopupMenuItem(
                    value: TasksDateFilterKind.today,
                    child: Text('Dzisiaj'),
                  ),
                  const PopupMenuItem(
                    value: TasksDateFilterKind.last7,
                    child: Text('Ostatnie 7 dni'),
                  ),
                  const PopupMenuItem(
                    value: TasksDateFilterKind.last30,
                    child: Text('Ostatnie 30 dni'),
                  ),
                  const PopupMenuItem(
                    value: TasksDateFilterKind.month,
                    child: Text('Miesiąc...'),
                  ),
                  const PopupMenuItem(
                    value: TasksDateFilterKind.year,
                    child: Text('Rok...'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(TasksDateFilterState filter) {
    switch (filter.kind) {
      case TasksDateFilterKind.all:
        return 'Wszystkie';
      case TasksDateFilterKind.today:
        return 'Dzisiaj';
      case TasksDateFilterKind.last7:
        return 'Ostatnie 7 dni';
      case TasksDateFilterKind.last30:
        return 'Ostatnie 30 dni';
      case TasksDateFilterKind.month:
        if (filter.year != null && filter.month != null) {
          return '${_monthName(filter.month!)} ${filter.year}';
        }
        return 'Wybierz miesiąc...';
      case TasksDateFilterKind.year:
        if (filter.year != null) return '${filter.year}';
        return 'Wybierz rok...';
    }
  }

  static const _monthNames = [
    'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień',
  ];
  static String _monthName(int month) =>
      month >= 1 && month <= 12 ? _monthNames[month - 1] : '?';

  Future<void> _onFilterSelected(
    BuildContext context,
    WidgetRef ref,
    TasksDateFilterKind kind,
  ) async {
    switch (kind) {
      case TasksDateFilterKind.all:
        ref.read(tasksDateFilterProvider.notifier).state = TasksDateFilterState.all;
        break;
      case TasksDateFilterKind.today:
        ref.read(tasksDateFilterProvider.notifier).state = TasksDateFilterState.today;
        break;
      case TasksDateFilterKind.last7:
        ref.read(tasksDateFilterProvider.notifier).state = TasksDateFilterState.last7;
        break;
      case TasksDateFilterKind.last30:
        ref.read(tasksDateFilterProvider.notifier).state = TasksDateFilterState.last30;
        break;
      case TasksDateFilterKind.month:
        final now = DateTime.now();
        final picked = await showDialog<({int year, int month})>(
          context: context,
          builder: (ctx) => _MonthYearPickerDialog(
            initialYear: now.year,
            initialMonth: now.month,
          ),
        );
        if (picked != null && context.mounted) {
          ref.read(tasksDateFilterProvider.notifier).state =
              TasksDateFilterState.forMonth(picked.year, picked.month);
        }
        break;
      case TasksDateFilterKind.year:
        final now = DateTime.now();
        final picked = await showDialog<int>(
          context: context,
          builder: (ctx) => _YearPickerDialog(initialYear: now.year),
        );
        if (picked != null && context.mounted) {
          ref.read(tasksDateFilterProvider.notifier).state = TasksDateFilterState.forYear(picked);
        }
        break;
    }
  }
}

/// Dialog wyboru miesiąca i roku.
class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  final int initialYear;
  final int initialMonth;

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;
  late int _month;

  static const _monthNames = [
    'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(11, (i) => DateTime.now().year - 5 + i);
    return AlertDialog(
      title: const Text('Wybierz miesiąc'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _year,
            decoration: const InputDecoration(labelText: 'Rok'),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) => setState(() => _year = v ?? _year),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _month,
            decoration: const InputDecoration(labelText: 'Miesiąc'),
            items: List.generate(12, (i) => i + 1)
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(_monthNames[m - 1]),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _month = v ?? _month),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((year: _year, month: _month)),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Dialog wyboru roku.
class _YearPickerDialog extends StatefulWidget {
  const _YearPickerDialog({required this.initialYear});

  final int initialYear;

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(11, (i) => DateTime.now().year - 5 + i);
    return AlertDialog(
      title: const Text('Wybierz rok'),
      content: DropdownButtonFormField<int>(
        value: _year,
        decoration: const InputDecoration(labelText: 'Rok'),
        items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
        onChanged: (v) => setState(() => _year = v ?? _year),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_year),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Przycisk „Statystyki kategorii” – po kliknięciu otwiera statystyki w bottom sheet.
class _CategoryStatsButton extends ConsumerWidget {
  const _CategoryStatsButton({required this.categoryId});

  final String categoryId;

  static StatsRange _initialRangeFromFilter(TasksDateFilterState filter) {
    final now = DateTime.now();
    if (filter.kind == TasksDateFilterKind.month &&
        filter.year == now.year &&
        filter.month == now.month) {
      return StatsRange.thisMonth;
    }
    return StatsRange.all;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    final filter = ref.watch(tasksDateFilterProvider);
    final categoryName = category?.name ?? 'Kategoria';
    final categoryColorHex = category?.colorHex;
    final initialRange = _initialRangeFromFilter(filter);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 1,
              expand: false,
              builder: (_, scrollController) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          'Statystyki kategorii',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                          tooltip: 'Zamknij',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: CategoryStatsBody(
                      categoryId: categoryId,
                      categoryName: categoryName,
                      categoryColorHex: categoryColorHex,
                      initialRange: initialRange,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.bar_chart_outlined, size: 20),
        label: const Text('Statystyki kategorii'),
      ),
    );
  }
}

class _TasksOfCategory extends ConsumerWidget {
  const _TasksOfCategory({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksByCategoryProvider(categoryId));
    final filter = ref.watch(tasksDateFilterProvider);

    return tasksAsync.when(
      data: (tasks) {
        // Filtruj według okresu (zadania już są przefiltrowane po zakończonych sesjach w providerze)
        final filtered = tasks
            .where((t) => filter.contains(t.createdAt))
            .toList();
        
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  tasks.isEmpty
                      ? 'Brak ukończonych zadań w tej kategorii.'
                      : 'Brak ukończonych zadań w wybranym okresie.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          );
        }
        final category = ref.watch(categoryByIdProvider(categoryId));
        final categoryColorHex = category?.colorHex;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) => MinimalTaskCard(
            key: ValueKey(filtered[index].id),
            task: filtered[index],
            categoryColorHex: categoryColorHex,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}

/// Kropka wyboru koloru z pewnym obszarem dotyku.
class _ColorPickerDot extends StatelessWidget {
  const _ColorPickerDot({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CategoryColors.parse(hex),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog edycji nazwy kategorii – controller w initState/dispose, unika crasha po dispose.
class _EditCategoryDialogContent extends StatefulWidget {
  const _EditCategoryDialogContent({required this.category});

  final CategoryRow category;

  @override
  State<_EditCategoryDialogContent> createState() => _EditCategoryDialogContentState();
}

class _EditCategoryDialogContentState extends State<_EditCategoryDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nazwa kategorii'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nazwa',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) {
          final trimmed = v.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            final v = _controller.text.trim();
            Navigator.of(context).pop(v.isEmpty ? null : v);
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}
