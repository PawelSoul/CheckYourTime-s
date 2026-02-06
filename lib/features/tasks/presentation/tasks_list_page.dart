import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../calendar/application/calendar_providers.dart';
import '../tasks_providers.dart';
import 'widgets/category_glass_tile.dart';
import 'widgets/task_glass_card.dart';

class TasksListPage extends ConsumerWidget {
  const TasksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lewa: lista kategorii
          Material(
            elevation: 0,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Brak kategorii.\nPrzejdź do Stoper,\nżeby dodać nową i zacząć odliczanie.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category.id;
                      return CategoryGlassTile(
                        category: category,
                        isSelected: isSelected,
                        onTap: () =>
                            ref.read(selectedCategoryProvider.notifier).state = category.id,
                        onLongPress: () =>
                            _showCategoryOptionsSheet(context, ref, category),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ),
            ),
          ),
          // Prawa: taski wybranej kategorii
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
                          'Kliknij kategorię po lewej,\nżeby zobaczyć listę zadań.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : _TasksOfCategory(categoryId: selectedCategory),
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

class _TasksOfCategory extends ConsumerWidget {
  const _TasksOfCategory({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksByCategoryProvider(categoryId));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'Brak zadań w tej kategorii.\nUruchom stoper i zatrzymaj go,\nżeby dodać pierwszy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        final category = ref.watch(categoryByIdProvider(categoryId));
        final categoryColorHex = category?.colorHex;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskGlassCard(
            task: tasks[index],
            categoryColorHex: categoryColorHex,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
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

/// Wybrana kategoria (do pokazania tasków po prawej).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
