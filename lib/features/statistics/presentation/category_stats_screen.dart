import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_colors.dart';
import '../application/statistics_providers.dart';
import '../application/stats_settings_provider.dart';
import '../domain/models/statistics_models.dart';
import 'widgets/category_stats_panel.dart';

/// Argumenty ekranu statystyk kategorii (z ekranu Zadania).
class CategoryStatsScreenArgs {
  const CategoryStatsScreenArgs({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColorHex,
    required this.initialRange,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryColorHex;
  final StatsRange initialRange;

  static CategoryStatsScreenArgs? fromExtra(Object? extra) {
    if (extra is Map<String, dynamic>) {
      final categoryId = extra['categoryId'] as String?;
      final categoryName = extra['categoryName'] as String?;
      if (categoryId == null || categoryName == null) return null;
      final initialRange = extra['initialRange'] == 'thisMonth'
          ? StatsRange.thisMonth
          : StatsRange.all;
      return CategoryStatsScreenArgs(
        categoryId: categoryId,
        categoryName: categoryName,
        categoryColorHex: extra['categoryColorHex'] as String?,
        initialRange: initialRange,
      );
    }
    return null;
  }
}

/// Ekran „Statystyki kategorii” – dashboard z wykresami i kartami (wg ustawień).
class CategoryStatsScreen extends ConsumerStatefulWidget {
  const CategoryStatsScreen({
    super.key,
    required this.args,
  });

  final CategoryStatsScreenArgs args;

  @override
  ConsumerState<CategoryStatsScreen> createState() => _CategoryStatsScreenState();
}

class _CategoryStatsScreenState extends ConsumerState<CategoryStatsScreen> {
  late StatsRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.args.initialRange;
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(
      categoryStatsProvider(CategoryStatsParams(
        categoryId: widget.args.categoryId,
        range: _selectedRange,
      )),
    );
    final settings = ref.watch(statsSettingsProvider);
    final categoryColor = CategoryColors.parse(widget.args.categoryColorHex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki kategorii'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nazwa kategorii + kolorowa kropka
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.args.categoryName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            // Przełącznik zakresu
            RangeSelector(
              selectedRange: _selectedRange,
              onRangeChanged: (range) => setState(() => _selectedRange = range),
            ),
            const SizedBox(height: 20),
            // Zawartość statystyk
            statsAsync.when(
              data: (stats) {
                if (stats == null) {
                  return EmptyState(message: 'Brak ukończonych sesji w tym zakresie');
                }
                return StatsContent(
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
              error: (err, stack) => EmptyState(
                message: 'Błąd ładowania statystyk: ${err.toString()}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
