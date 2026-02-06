import 'package:flutter/material.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import 'package:checkyourtime/core/utils/datetime_utils.dart';
import 'package:checkyourtime/core/widgets/glass_card.dart';
import '../../../data/db/daos/tasks_dao.dart';

/// Ekran szczegółów zadania – otwierany po kliknięciu karty na liście.
class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({
    super.key,
    required this.task,
    this.categoryColorHex,
  });

  final TaskRow task;
  final String? categoryColorHex;

  @override
  Widget build(BuildContext context) {
    final colorHex = categoryColorHex ?? task.colorHex;
    final baseColor = CategoryColors.parse(colorHex);
    final accentColor = _accentColor(baseColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły zadania'),
        actions: [
          IconButton(
            icon: const Text('✏️', style: TextStyle(fontSize: 20)),
            tooltip: 'Edycja (wkrótce)',
            onPressed: null,
          ),
          IconButton(
            icon: const Text('🗑', style: TextStyle(fontSize: 20)),
            tooltip: 'Usuń (wkrótce)',
            onPressed: null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderSection(
            taskName: task.name,
            createdAtMs: task.createdAt,
            accentColor: accentColor,
          ),
          const SizedBox(height: 20),
          const _StatisticsSection(),
          const SizedBox(height: 20),
          const _ActionsSection(),
        ],
      ),
    );
  }

  static Color _accentColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withSaturation((hsl.saturation * 0.6).clamp(0.0, 1.0)).toColor();
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.taskName,
    required this.createdAtMs,
    required this.accentColor,
  });

  final String taskName;
  final int createdAtMs;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 10, top: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  taskName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              DateTimeUtils.formatTaskDateTimeFromEpochMs(createdAtMs),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statystyki',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wkrótce: czas trwania, historia sesji, streak, wykresy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Akcje',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: null,
                  child: const Text('Edytuj'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Usuń'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
