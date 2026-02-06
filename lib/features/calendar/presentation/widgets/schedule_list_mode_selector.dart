import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar_providers.dart';

/// Przełącznik trybu listy: „Oś czasu” / „Według kategorii”.
class ScheduleListModeSelector extends ConsumerWidget {
  const ScheduleListModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(scheduleListModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: SegmentedButton<ScheduleListMode>(
        segments: const [
          ButtonSegment<ScheduleListMode>(
            value: ScheduleListMode.timeline,
            label: Text('Oś czasu'),
            icon: Icon(Icons.timeline, size: 18),
          ),
          ButtonSegment<ScheduleListMode>(
            value: ScheduleListMode.byCategory,
            label: Text('Według kategorii'),
            icon: Icon(Icons.category_outlined, size: 18),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (Set<ScheduleListMode> selected) {
          ref.read(scheduleListModeProvider.notifier).state = selected.first;
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6);
            }
            return Colors.white.withOpacity(0.04);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.onPrimaryContainer;
            }
            return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
      ),
    );
  }
}
