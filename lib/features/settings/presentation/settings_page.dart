import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../timer/application/timer_view_settings.dart';
import '../../tasks/presentation/tasks_list_page.dart';
import '../../tasks/tasks_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Timer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(timerViewSettingsProvider);
              final notifier = ref.read(timerViewSettingsProvider.notifier);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TimerModeSegment(
                        label: 'Cyfrowy',
                        icon: Icons.schedule,
                        isSelected: settings.viewMode == TimerViewMode.digital,
                        onTap: () => notifier.setViewMode(TimerViewMode.digital),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TimerModeSegment(
                        label: 'Analogowy',
                        icon: Icons.access_time,
                        isSelected: settings.viewMode == TimerViewMode.analog,
                        onTap: () => notifier.setViewMode(TimerViewMode.analog),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(timerViewSettingsProvider);
              final notifier = ref.read(timerViewSettingsProvider.notifier);
              if (settings.viewMode != TimerViewMode.analog) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text('2 (min + sek)'),
                    subtitle: const Text('Tylko minutowa i sekundowa'),
                    leading: Radio<AnalogHandsMode>(
                      value: AnalogHandsMode.two,
                      groupValue: settings.analogHandsMode,
                      onChanged: (v) {
                        if (v != null) notifier.setAnalogHandsMode(v);
                      },
                    ),
                    onTap: () => notifier.setAnalogHandsMode(AnalogHandsMode.two),
                  ),
                  ListTile(
                    title: const Text('3 (godz + min + sek)'),
                    subtitle: const Text('Godzinowa, minutowa i sekundowa'),
                    leading: Radio<AnalogHandsMode>(
                      value: AnalogHandsMode.three,
                      groupValue: settings.analogHandsMode,
                      onChanged: (v) {
                        if (v != null) notifier.setAnalogHandsMode(v);
                      },
                    ),
                    onTap: () => notifier.setAnalogHandsMode(AnalogHandsMode.three),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Styl cyfer',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Duże i czytelne'),
                    leading: Radio<AnalogNumbersStyle>(
                      value: AnalogNumbersStyle.large,
                      groupValue: settings.analogNumbersStyle,
                      onChanged: (v) {
                        if (v != null) notifier.setAnalogNumbersStyle(v);
                      },
                    ),
                    onTap: () => notifier.setAnalogNumbersStyle(AnalogNumbersStyle.large),
                  ),
                  ListTile(
                    title: const Text('Subtelne'),
                    leading: Radio<AnalogNumbersStyle>(
                      value: AnalogNumbersStyle.subtle,
                      groupValue: settings.analogNumbersStyle,
                      onChanged: (v) {
                        if (v != null) notifier.setAnalogNumbersStyle(v);
                      },
                    ),
                    onTap: () => notifier.setAnalogNumbersStyle(AnalogNumbersStyle.subtle),
                  ),
                ],
              );
            },
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
}

class _TimerModeSegment extends StatelessWidget {
  const _TimerModeSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
