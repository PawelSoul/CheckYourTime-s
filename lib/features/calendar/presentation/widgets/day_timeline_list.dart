import 'package:flutter/material.dart';

import 'package:checkyourtime/core/utils/datetime_utils.dart';
import '../../domain/calendar_models.dart';

/// Model wejściowy: używamy [TimelineItemVm] (title, startAt, endAt?, categoryColor).
/// Brak endAt lub end < start → traktujemy end = start (minimalny blok, obie kropki).

/// Czysta pionowa oś dnia: jedna linia, dwie kropki na zadanie (start + end), czas przy kropce, tytuł po prawej.
class DayAxisTimeline extends StatelessWidget {
  const DayAxisTimeline({super.key, required this.tasks});

  final List<TimelineItemVm> tasks;

  static List<TimelineItemVm> _sortedByStart(List<TimelineItemVm> list) {
    final copy = List<TimelineItemVm>.from(list);
    copy.sort((a, b) => a.startAt.compareTo(b.startAt));
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final sorted = _sortedByStart(tasks);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: sorted.length,
      itemBuilder: (context, index) => TaskTimelineBlock(entry: sorted[index]),
    );
  }
}

/// Mapowanie długości (minuty) na wysokość bloku. min=56, max=160.
double mapDurationToHeight(int durationMinutes) {
  const minH = 56.0;
  const maxH = 160.0;
  if (durationMinutes <= 0) return minH;
  const span = maxH - minH;
  final height = minH + (durationMinutes / 60.0).clamp(0.0, 1.0) * span;
  return height.clamp(minH, maxH);
}

/// Jedna „karta” na osi: oś + kropka start + kropka end + czasy przy kropkach + tytuł po prawej.
class TaskTimelineBlock extends StatelessWidget {
  const TaskTimelineBlock({super.key, required this.entry});

  final TimelineItemVm entry;

  static const double axisX = 28.0;
  static const double leftColumnWidth = 36.0;
  static const double dotRadius = 4.0;
  static const double axisLineWidth = 1.0;
  static const double blockPaddingTop = 8.0;
  static const double blockPaddingBottom = 8.0;
  static const double minEndDotOffset = 24.0; // gdy duration 0: end kropka +24px poniżej start

  static double heightForEntry(TimelineItemVm entry) {
    final durationMinutes = _durationMinutes(entry);
    return mapDurationToHeight(durationMinutes);
  }

  static int _durationMinutes(TimelineItemVm entry) {
    final start = entry.startAt;
    DateTime end = entry.endAt ?? start;
    if (end.isBefore(start)) end = start;
    final minutes = end.difference(start).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  @override
  Widget build(BuildContext context) {
    final height = heightForEntry(entry);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.6);
    final separatorColor = theme.dividerColor.withValues(alpha: 0.2);

    final startY = blockPaddingTop;
    int durationMinutes = _durationMinutes(entry);
    final endY = durationMinutes < 1
        ? startY + minEndDotOffset
        : height - blockPaddingBottom;

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: separatorColor, width: 1),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Segment osi (cienka linia pionowa w obrębie bloku)
          Positioned(
            left: axisX - axisLineWidth / 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: axisLineWidth,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Kropka start
          Positioned(
            left: axisX - dotRadius,
            top: startY - dotRadius,
            child: Container(
              width: dotRadius * 2,
              height: dotRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entry.categoryColor,
              ),
            ),
          ),
          // Kropka end
          Positioned(
            left: axisX - dotRadius,
            top: endY - dotRadius,
            child: Container(
              width: dotRadius * 2,
              height: dotRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entry.categoryColor,
              ),
            ),
          ),
          // Czas startu (na lewo od osi, wyśrodkowany z kropką start)
          Positioned(
            left: 0,
            top: startY - 10,
            width: axisX - 4,
            height: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatTime(entry.startAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          // Czas końca (na lewo od osi, wyśrodkowany z kropką end)
          Positioned(
            left: 0,
            top: endY - 10,
            width: axisX - 4,
            height: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatTime(_effectiveEnd(entry)),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          // Tytuł (i opcjonalna subline) po prawej, wyśrodkowany w pionie między kropkami
          Positioned(
            left: leftColumnWidth + 12,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subline(entry),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _effectiveEnd(TimelineItemVm entry) {
    final start = entry.startAt;
    final end = entry.endAt;
    if (end == null || end.isBefore(start)) return start;
    return end;
  }

  static String _subline(TimelineItemVm entry) {
    final startStr = formatTime(entry.startAt);
    final endStr = formatTime(_effectiveEnd(entry));
    return '$startStr – $endStr';
  }
}

/// Format czasu HH:mm. Używa [DateTimeUtils.formatTime].
String formatTime(DateTime dateTime) {
  return DateTimeUtils.formatTime(dateTime);
}
