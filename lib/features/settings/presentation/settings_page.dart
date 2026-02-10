import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../timer/application/timer_view_settings.dart';
import '../../tasks/tasks_providers.dart';

// --- Stałe stylu (iOS-like) ---
const _cardRadius = 16.0;
const _cardPadding = 16.0;
const _spacingBetweenCards = 14.0;
const _optionRowHeight = 56.0;
const _separatorHeight = 1.0;

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(timerViewSettingsProvider);
              final notifier = ref.read(timerViewSettingsProvider.notifier);
              return SettingsSectionCard(
                title: 'Timer',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SettingsSegmentedControl<String>(
                      options: const ['Cyfrowy', 'Analogowy'],
                      value: settings.viewMode == TimerViewMode.digital ? 'Cyfrowy' : 'Analogowy',
                      onChanged: (v) => notifier.setViewMode(
                        v == 'Cyfrowy' ? TimerViewMode.digital : TimerViewMode.analog,
                      ),
                    ),
                    if (settings.viewMode == TimerViewMode.analog) ...[
                      const SizedBox(height: 12),
                      _divider(context),
                      SettingsOptionTile<AnalogHandsMode>(
                        title: '2 (min + sek)',
                        subtitle: 'Tylko minutowa i sekundowa',
                        value: AnalogHandsMode.two,
                        groupValue: settings.analogHandsMode,
                        onTap: () => notifier.setAnalogHandsMode(AnalogHandsMode.two),
                        trailingType: TrailingType.radio,
                      ),
                      _divider(context),
                      SettingsOptionTile<AnalogHandsMode>(
                        title: '3 (godz + min + sek)',
                        subtitle: 'Godzinowa, minutowa i sekundowa',
                        value: AnalogHandsMode.three,
                        groupValue: settings.analogHandsMode,
                        onTap: () => notifier.setAnalogHandsMode(AnalogHandsMode.three),
                        trailingType: TrailingType.radio,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: _spacingBetweenCards),
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(timerViewSettingsProvider);
              final notifier = ref.read(timerViewSettingsProvider.notifier);
              if (settings.viewMode != TimerViewMode.analog) return const SizedBox.shrink();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: _spacingBetweenCards),
                  SettingsSectionCard(
                title: 'Liczby na tarczy',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SettingsOptionTile<bool>(
                      title: 'Widoczne',
                      value: true,
                      groupValue: settings.analogNumbersVisible,
                      onTap: () => notifier.setAnalogNumbersVisible(true),
                      trailingType: TrailingType.radio,
                    ),
                    _divider(context),
                    SettingsOptionTile<bool>(
                      title: 'Ukryte',
                      value: false,
                      groupValue: settings.analogNumbersVisible,
                      onTap: () => notifier.setAnalogNumbersVisible(false),
                      trailingType: TrailingType.radio,
                    ),
                  ],
                ),
                  ),
                ],
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(timerViewSettingsProvider);
              final notifier = ref.read(timerViewSettingsProvider.notifier);
              if (settings.viewMode != TimerViewMode.analog || !settings.analogNumbersVisible) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: _spacingBetweenCards),
                  SettingsSectionCard(
                title: 'Styl cyfr',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SettingsOptionTile<AnalogNumbersStyle>(
                      title: 'Duże i czytelne',
                      value: AnalogNumbersStyle.large,
                      groupValue: settings.analogNumbersStyle,
                      onTap: () => notifier.setAnalogNumbersStyle(AnalogNumbersStyle.large),
                      trailingType: TrailingType.radio,
                    ),
                    _divider(context),
                    SettingsOptionTile<AnalogNumbersStyle>(
                      title: 'Subtelne',
                      value: AnalogNumbersStyle.subtle,
                      groupValue: settings.analogNumbersStyle,
                      onTap: () => notifier.setAnalogNumbersStyle(AnalogNumbersStyle.subtle),
                      trailingType: TrailingType.radio,
                    ),
                  ],
                ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: _spacingBetweenCards),
          SettingsSectionCard(
            title: 'Dane',
            child: DestructiveActionTile(
              title: 'Wyczyść wszystkie dane',
              subtitle: 'Usunie wszystkie kategorie, zadania i sesje. Nie można cofnąć.',
              icon: Icons.delete_forever_outlined,
              onTap: () => _confirmClearAllData(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      height: _separatorHeight,
      margin: const EdgeInsets.only(left: 0),
      color: Theme.of(context).dividerColor.withOpacity(0.2),
    );
  }

  Future<void> _confirmClearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wyczyścić całą bazę?'),
        content: const Text(
          'Usunie wszystkie kategorie, zadania i sesje. Nie można cofnąć.',
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
            child: const Text('Wyczyść'),
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

// --- Komponenty wielokrotnego użytku ---

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Material(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh.withOpacity(0.6)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(_cardPadding),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

enum TrailingType { radio, check }

class SettingsOptionTile<T> extends StatelessWidget {
  const SettingsOptionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onTap,
    this.trailingType = TrailingType.radio,
  });

  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final VoidCallback onTap;
  final TrailingType trailingType;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Semantics(
      toggled: _selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _optionRowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: trailingType == TrailingType.radio
                        ? Radio<T>(
                            value: value,
                            groupValue: groupValue,
                            onChanged: (_) => onTap(),
                            activeColor: accent,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )
                        : Icon(
                            _selected ? Icons.check_circle : Icons.circle_outlined,
                            size: 24,
                            color: _selected ? accent : theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSegmentedControl<T> extends StatelessWidget {
  const SettingsSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Row(
      children: List.generate(options.length * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(width: 8);
        final index = i ~/ 2;
        final option = options[index];
        final label = option is String ? option : option.toString();
        final isSelected = option == value;
        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(option),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withOpacity(0.18)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: accent.withOpacity(0.5), width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? accent : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class DestructiveActionTile extends StatelessWidget {
  const DestructiveActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _optionRowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: errorColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: errorColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
