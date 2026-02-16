import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/statistics_providers.dart';
import '../../domain/models/statistics_models.dart';
import '../../domain/stats_widget_key.dart';
import '../utils/stats_explanations.dart';
import '../utils/stats_format_utils.dart';

/// Karta: Łączny czas w kategorii.
class TotalTimeCard extends StatelessWidget {
  const TotalTimeCard({super.key, required this.totalTimeSeconds});

  final int totalTimeSeconds;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      title: 'Łączny czas',
      value: StatsFormatUtils.formatTotalTime(totalTimeSeconds),
      explanationKey: 'totalTime',
    );
  }
}

/// Karta: Średnia długość sesji.
class AverageSessionDurationCard extends StatelessWidget {
  const AverageSessionDurationCard({
    super.key,
    required this.averageDurationSeconds,
  });

  final double averageDurationSeconds;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      title: 'Średnia długość sesji',
      value: StatsFormatUtils.formatDuration(averageDurationSeconds.round()),
      explanationKey: 'averageSessionDuration',
    );
  }
}

/// Karta: Porównanie do średniej.
class ShareVsAverageCard extends StatelessWidget {
  const ShareVsAverageCard({super.key, required this.shareVsAverage});

  final ShareVsAverage shareVsAverage;

  @override
  Widget build(BuildContext context) {
    final diffText = shareVsAverage.differencePercent >= 0
        ? '+${shareVsAverage.differencePercent.toStringAsFixed(1)}%'
        : '${shareVsAverage.differencePercent.toStringAsFixed(1)}%';

    return _StatsCard(
      title: 'Porównanie do średniej',
      value: '${shareVsAverage.categorySharePercent.toStringAsFixed(1)}% całkowitego czasu',
      subtitle: 'vs średnia na kategorię: $diffText',
      explanationKey: 'shareVsAverage',
    );
  }
}

/// Karta: Najbardziej produktywny dzień tygodnia.
class MostProductiveWeekdayCard extends StatelessWidget {
  const MostProductiveWeekdayCard({super.key, required this.weekday});

  final int weekday; // 1=Mon, 7=Sun

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      title: 'Najbardziej produktywny dzień',
      value: StatsFormatUtils.formatWeekday(weekday),
      explanationKey: 'mostProductiveWeekday',
    );
  }
}

/// Karta: Streak.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      title: 'Streak',
      value: '$streak ${streak == 1 ? 'dzień' : 'dni'}',
      subtitle: 'Minimum 2 sesje i ≥10 min dziennie',
      explanationKey: 'streak',
    );
  }
}

/// Karta: Najczęstsza godzina pracy.
class PeakHourCard extends StatelessWidget {
  const PeakHourCard({
    super.key,
    required this.peakHourRange,
    required this.histogram,
  });

  final String peakHourRange;
  final List<HourBucket> histogram;

  @override
  Widget build(BuildContext context) {
    final maxCount = histogram.map((h) => h.sessionCount).reduce((a, b) => a > b ? a : b);

    return _StatsCard(
      title: 'Najczęstsza godzina pracy',
      value: peakHourRange,
      subtitle: 'Histogram aktywności',
      explanationKey: 'peakHour',
      customContent: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: histogram.map((bucket) {
            final height = maxCount > 0 ? (bucket.sessionCount / maxCount) : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(
                              height.clamp(0.1, 1.0),
                            ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bucket.hour}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Karta: Ranking kategorii.
class CategoryRankingCard extends ConsumerWidget {
  const CategoryRankingCard({
    super.key,
    required this.categoryId,
    required this.range,
  });

  final String categoryId;
  final StatsRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(categoryRankingProvider(range));

    return rankingAsync.when(
      data: (ranking) {
        if (ranking.isEmpty) {
          return _StatsCard(
            title: 'Ranking kategorii',
            value: 'Brak danych',
          );
        }

        final currentCategoryIndex = ranking.indexWhere((e) => e.categoryId == categoryId);
        final currentCategory = currentCategoryIndex >= 0 ? ranking[currentCategoryIndex] : null;

        return _StatsCard(
          title: 'Ranking kategorii',
          value: currentCategory != null
              ? 'Pozycja ${currentCategory.position} z ${ranking.length}'
              : 'Poza rankingiem',
          explanationKey: 'categoryRanking',
          customContent: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: ranking.take(5).map((entry) {
                final isCurrent = entry.categoryId == categoryId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrent
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${entry.position}.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.categoryName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                      ),
                      Text(
                        StatsFormatUtils.formatTotalTime(entry.totalTimeSeconds),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const _StatsCard(
        title: 'Ranking kategorii',
        value: 'Ładowanie...',
        explanationKey: 'categoryRanking',
      ),
      error: (err, stack) => _StatsCard(
        title: 'Ranking kategorii',
        value: 'Błąd: ${err.toString()}',
        explanationKey: 'categoryRanking',
      ),
    );
  }
}

/// Bazowa karta statystyki.
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.customContent,
    this.explanationKey,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Widget? customContent;
  final String? explanationKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (explanationKey != null)
                InkWell(
                  onTap: () => showExplanationDialog(context, explanationKey!),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
            ),
          ],
          if (customContent != null) customContent!,
        ],
      ),
    );
  }

  static void showExplanationDialog(BuildContext context, String explanationKey) {
    final explanation = StatsExplanations.get(explanationKey);
    if (explanation == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(ctx).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Wyjaśnienie')),
          ],
        ),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Rozumiem'),
          ),
        ],
      ),
    );
  }
}
