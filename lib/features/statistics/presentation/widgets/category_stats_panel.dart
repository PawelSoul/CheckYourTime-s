import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/category_colors.dart';
import '../../application/statistics_providers.dart';
import '../../application/stats_settings_provider.dart';
import '../../domain/models/statistics_models.dart';
import '../../domain/stats_widget_key.dart';
import '../utils/stats_format_utils.dart';
import 'stats_cards.dart';
import 'stats_charts.dart';

/// Panel statystyk kategorii z dynamiczną listą kart wg ustawień.
class CategoryStatsPanel extends ConsumerStatefulWidget {
  const CategoryStatsPanel({
    super.key,
    required this.categoryId,
    required this.categoryColorHex,
  });

  final String categoryId;
  final String? categoryColorHex;

  @override
  ConsumerState<CategoryStatsPanel> createState() => _CategoryStatsPanelState();
}

class _CategoryStatsPanelState extends ConsumerState<CategoryStatsPanel> {
  StatsRange _selectedRange = StatsRange.all;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(
      categoryStatsProvider(CategoryStatsParams(
        categoryId: widget.categoryId,
        range: _selectedRange,
      )),
    );
    final settings = ref.watch(statsSettingsProvider);
    final categoryColor = CategoryColors.parse(widget.categoryColorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Przełącznik zakresu
          _RangeSelector(
            selectedRange: _selectedRange,
            onRangeChanged: (range) => setState(() => _selectedRange = range),
          ),
          const SizedBox(height: 20),
          // Zawartość statystyk
          statsAsync.when(
            data: (stats) {
              if (stats == null) {
                return _EmptyState(message: 'Brak ukończonych sesji w tym zakresie');
              }
              return _StatsContent(
                stats: stats,
                categoryColor: categoryColor,
                settings: settings,
                range: _selectedRange,
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => _EmptyState(
              message: 'Błąd ładowania statystyk: ${err.toString()}',
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final StatsRange selectedRange;
  final ValueChanged<StatsRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsRange>(
      segments: const [
        ButtonSegment(
          value: StatsRange.all,
          label: Text('Wszystkie'),
        ),
        ButtonSegment(
          value: StatsRange.thisMonth,
          label: Text('Ten miesiąc'),
        ),
      ],
      selected: {selectedRange},
      onSelectionChanged: (Set<StatsRange> selection) {
        if (selection.isNotEmpty) {
          onRangeChanged(selection.first);
        }
      },
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({
    required this.stats,
    required this.categoryColor,
    required this.settings,
    required this.range,
  });

  final CategoryStats stats;
  final Color categoryColor;
  final StatsSettings settings;
  final StatsRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgets = <Widget>[];

    // Sekcja: Podsumowanie
    final summaryWidgets = <Widget>[];
    if (settings.isEnabled(StatsWidgetKey.totalTime)) {
      summaryWidgets.add(
        TotalTimeCard(totalTimeSeconds: stats.totalTimeSeconds),
      );
    }
    if (settings.isEnabled(StatsWidgetKey.averageSessionDuration)) {
      summaryWidgets.add(
        AverageSessionDurationCard(
          averageDurationSeconds: stats.averageSessionDurationSeconds,
        ),
      );
    }
    if (settings.isEnabled(StatsWidgetKey.shareVsAverage) && stats.shareVsAverage != null) {
      summaryWidgets.add(
        ShareVsAverageCard(shareVsAverage: stats.shareVsAverage!),
      );
    }

    if (summaryWidgets.isNotEmpty) {
      widgets.add(
        _SectionHeader(title: 'Podsumowanie'),
      );
      widgets.addAll(summaryWidgets);
      widgets.add(const SizedBox(height: 16));
    }

    // Sekcja: Wykresy
    final chartWidgets = <Widget>[];
    if (settings.isEnabled(StatsWidgetKey.last7DaysChart)) {
      chartWidgets.add(
        Last7DaysBarChart(
          data: stats.last7Days,
          color: categoryColor,
        ),
      );
    }
    if (settings.isEnabled(StatsWidgetKey.trend30Days) && stats.trend30Days != null) {
      chartWidgets.add(
        Trend30DaysLineChart(
          trendData: stats.trend30Days!,
          color: categoryColor,
        ),
      );
    }

    if (chartWidgets.isNotEmpty) {
      widgets.add(_SectionHeader(title: 'Wykresy'));
      widgets.addAll(chartWidgets);
      widgets.add(const SizedBox(height: 16));
    }

    // Sekcja: Wzorce
    final patternWidgets = <Widget>[];
    if (settings.isEnabled(StatsWidgetKey.mostProductiveWeekday) &&
        stats.mostProductiveWeekday != null) {
      patternWidgets.add(
        MostProductiveWeekdayCard(
          weekday: stats.mostProductiveWeekday!,
        ),
      );
    }
    if (settings.isEnabled(StatsWidgetKey.streak)) {
      patternWidgets.add(
        StreakCard(streak: stats.streak),
      );
    }
    if (settings.isEnabled(StatsWidgetKey.peakHour) && stats.peakHourRange != null) {
      patternWidgets.add(
        PeakHourCard(
          peakHourRange: stats.peakHourRange!,
          histogram: stats.hourHistogram,
        ),
      );
    }

    if (patternWidgets.isNotEmpty) {
      widgets.add(_SectionHeader(title: 'Wzorce'));
      widgets.addAll(patternWidgets);
      widgets.add(const SizedBox(height: 16));
    }

    // Sekcja: Ranking
    if (settings.isEnabled(StatsWidgetKey.categoryRanking)) {
      widgets.add(_SectionHeader(title: 'Ranking'));
      widgets.add(
        CategoryRankingCard(
          categoryId: stats.categoryId,
          range: range,
        ),
      );
    }

    if (widgets.isEmpty) {
      return _EmptyState(message: 'Wszystkie statystyki są wyłączone w ustawieniach');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
      ),
    );
  }
}
