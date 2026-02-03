import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/calendar_providers.dart';
import 'widgets/session_event_tile.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  static const _monthNames = [
    'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
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
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(calendarMonthProvider.notifier).update(
                    (m) => DateTime(m.year, m.month + 1),
                  );
            },
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Brak sesji w tym miesiącu.\nUruchom stoper i zatrzymaj go, żeby dodać kafelek.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) => SessionEventTile(sessionWithTask: sessions[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
