import 'package:flutter/material.dart';

import 'package:checkyourtime/core/utils/datetime_utils.dart';
import 'package:checkyourtime/core/widgets/glass_card.dart';
import '../../domain/calendar_models.dart';

/// Lista sesji w trybie „Według kategorii”: grupy z nagłówkiem (kropka + nazwa + suma) i prostą listą sesji [1] HH:mm.
class GroupedByCategoryView extends StatelessWidget {
  const GroupedByCategoryView({super.key, required this.groups});

  final List<CategoryGroupVm> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final totalSec = group.items.fold<int>(0, (sum, i) => sum + i.durationSec);
        final totalStr = DateTimeUtils.formatDurationSeconds(totalSec);
        final sortedItems = List<TimelineItemVm>.from(group.items)
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CategoryHeader(
                  categoryName: group.categoryName,
                  categoryColor: group.categoryColor,
                  totalDurationStr: totalStr,
                ),
                const SizedBox(height: 12),
                if (sortedItems.isEmpty)
                  _EmptySessionsHint()
                else
                  _SessionList(items: sortedItems),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Nagłówek kategorii: [kropka] Nazwa • SUMA_CZASU (semi-bold).
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.categoryName,
    required this.categoryColor,
    required this.totalDurationStr,
  });

  final String categoryName;
  final Color categoryColor;
  final String totalDurationStr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: categoryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$categoryName • $totalDurationStr',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Lista sesji: [1] HH:mm – HH:mm, [2] …, z lekkim separatorem między wierszami.
class _SessionList extends StatelessWidget {
  const _SessionList({required this.items});

  final List<TimelineItemVm> items;

  static const double _rowSpacing = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: _rowSpacing),
          _SessionRow(
            index: i + 1,
            startAt: items[i].startAt,
            endAt: items[i].endAt,
            counterColor: muted,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

/// Jedna sesja: [index]  godzina rozpoczęcia – godzina zakończenia.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.index,
    required this.startAt,
    this.endAt,
    required this.counterColor,
    required this.theme,
  });

  final int index;
  final DateTime startAt;
  final DateTime? endAt;
  final Color counterColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final end = endAt != null && !endAt!.isBefore(startAt) ? endAt! : startAt;
    final timeStr = '${DateTimeUtils.formatTime(startAt)} – ${DateTimeUtils.formatTime(end)}';

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '[$index]',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: counterColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            timeStr,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Gdy brak sesji w kategorii.
class _EmptySessionsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Brak sesji',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
    );
  }
}
