import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/calendar_providers.dart';
import 'widgets/day_schedule_view.dart';
import 'widgets/month_view.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  static const _monthNames = [
    'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final sessionsAsync = ref.watch(calendarSessionsProvider);
    final monthTitle = '${_monthNames[month.month - 1]} ${month.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(monthTitle),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(calendarMonthProvider.notifier).update(
                  (m) => DateTime(m.year, m.month - 1),
                );
            ref.read(selectedDayProvider.notifier).state = null;
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(calendarMonthProvider.notifier).update(
                    (m) => DateTime(m.year, m.month + 1),
                  );
              ref.read(selectedDayProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonthView(
                  month: month,
                  sessions: sessions,
                  selectedDay: selectedDay,
                  onDaySelected: (day) {
                    ref.read(selectedDayProvider.notifier).state = day;
                  },
                ),
                if (selectedDay != null) ...[
                  const SizedBox(height: 24),
                  DayScheduleView(
                    day: selectedDay,
                    sessionsInMonth: sessions,
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'Kliknij dzień, żeby zobaczyć sesje',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
