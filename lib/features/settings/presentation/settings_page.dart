import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../tasks/presentation/tasks_list_page.dart';
import '../../tasks/tasks_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Wygląd',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Tryb motywu'),
            subtitle: Text(themeMode.displayName),
            onTap: () => _showThemePicker(context, ref),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Dane',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Wyczyść wszystkie dane',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Usunie wszystkie kategorie, zadania i sesje. Nie można cofnąć.'),
            onTap: () => _confirmClearAllData(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wyczyścić całą bazę?'),
        content: const Text(
          'Zostaną usunięte wszystkie kategorie, zadania i sesje. Tej operacji nie można cofnąć.',
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
            child: const Text('Wyczyść wszystko'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final db = ref.read(appDbProvider);
    final sessionsDao = ref.read(sessionsDaoProvider);
    final tasksDao = ref.read(tasksDaoProvider);
    final categoriesDao = ref.read(categoriesDaoProvider);

    await db.transaction(() async {
      await sessionsDao.deleteAllSessions();
      await tasksDao.deleteAllTasks();
      await categoriesDao.deleteAllCategories();
    });

    if (!context.mounted) return;
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.invalidate(calendarSessionsProvider);
    ref.invalidate(categoriesStreamProvider);
    ref.invalidate(tasksStreamProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wszystkie dane zostały usunięte')),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tryb motywu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...AppThemeMode.values.map((mode) {
              final isSelected = mode == current;
              return ListTile(
                leading: Icon(
                  _iconFor(mode),
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  mode.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
