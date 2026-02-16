import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/category_colors.dart';
import '../../../../features/statistics/application/statistics_providers.dart';
import '../../../../features/statistics/presentation/utils/stats_format_utils.dart';
import '../../application/tasks_date_filter.dart';
import '../../tasks_providers.dart';

/// Minimalna karta „Podsumowanie kategorii” nad listą zadań.
/// Tap → nawigacja na ekran Statystyki kategorii.
class CategorySummaryCard extends ConsumerWidget {
  const CategorySummaryCard({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColorHex,
    required this.currentFilterState,
    required this.onTap,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryColorHex;
  final TasksDateFilterState currentFilterState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(
      categorySummaryTotalSecondsProvider(CategorySummaryParams(
        categoryId: categoryId,
        filterState: currentFilterState,
      )),
    );
    final color = CategoryColors.parse(categoryColorHex);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: color,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: totalAsync.when(
                  data: (totalSec) {
                    final totalStr = StatsFormatUtils.formatTotalTime(totalSec);
                    return Text(
                      'Kategoria: $categoryName  |  Łącznie: $totalStr  |  📊 Statystyki →',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  loading: () => Text(
                    'Kategoria: $categoryName  |  Łącznie: …  |  📊 Statystyki →',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  error: (_, __) => Text(
                    'Kategoria: $categoryName  |  Łącznie: 0m  |  📊 Statystyki →',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
