import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:checkyourtime/core/utils/datetime_utils.dart';
import '../../domain/calendar_models.dart';

/// Model wejściowy: [TimelineItemVm]. Brak endAt lub end < start → end = start (min. blok).
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: sorted.length,
      itemBuilder: (context, index) => TaskTimelineItem(entry: sorted[index]),
    );
  }
}

/// Wysokość bloku: base 56 + sqrt(durationMinutes)*12, clamp 56..140.
double mapDurationToHeight(int durationMinutes) {
  const minH = 56.0;
  const maxH = 140.0;
  if (durationMinutes <= 0) return minH;
  final h = minH + math.sqrt(durationMinutes.toDouble()) * 12;
  return h.clamp(minH, maxH);
}

/// Jedna pozycja na osi: kolumna czasu | oś + kropki | tytuł (minimalnie).
class TaskTimelineItem extends StatelessWidget {
  const TaskTimelineItem({super.key, required this.entry});

  final TimelineItemVm entry;

  // --- Kolumny (strict 3-column layout) ---
  /// Kolumna A: gutter na etykiety czasu (HH:mm). Szerokość 56–68.
  static const double timeGutterWidth = 60.0;
  /// Kolumna B: oś + kropki. Oś wyśrodkowana w tej kolumnie.
  static const double axisColumnWidth = 24.0;
  /// Pozycja X środka osi (początek A + szerokość A + połowa B).
  static const double axisX = timeGutterWidth + axisColumnWidth / 2;
  /// Szerokość A+B; tytuł zaczyna się po tym + padding.
  static const double leftColumnsWidth = timeGutterWidth + axisColumnWidth;

  // --- Oś i kropki ---
  static const double axisLineWidth = 1.0;
  static const double dotRadius = 3.5;

  // --- Pionowe pozycje w bloku ---
  static const double topPadding = 10.0;
  static const double bottomPadding = 10.0;
  /// Minimalna odległość między środkami kropki start i end (żeby nie nakładały się).
  static const double minDotGap = 22.0;
  /// Odstęp między tekstem czasu a osią.
  static const double timeToAxisGap = 8.0;

  // --- Tytuł (pill) ---
  static const double titlePaddingH = 12.0;
  static const double titlePaddingV = 10.0;
  static const double titleBorderRadius = 10.0;

  static double heightForEntry(TimelineItemVm entry) {
    return mapDurationToHeight(_durationMinutes(entry));
  }

  static int _durationMinutes(TimelineItemVm entry) {
    final start = entry.startAt;
    DateTime end = entry.endAt ?? start;
    if (end.isBefore(start)) end = start;
    final minutes = end.difference(start).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  static DateTime _effectiveEnd(TimelineItemVm entry) {
    final start = entry.startAt;
    final end = entry.endAt;
    if (end == null || end.isBefore(start)) return start;
    return end;
  }

  @override
  Widget build(BuildContext context) {
    final blockHeight = heightForEntry(entry);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final timeColor = onSurface.withValues(alpha: 0.72);
    final axisColor = onSurface.withValues(alpha: 0.12);
    final titleBg = onSurface.withValues(alpha: 0.06);
    final separatorColor = onSurface.withValues(alpha: 0.06);

    // Środki kropków: start u góry, end u dołu; zachowaj minDotGap
    final startY = topPadding + dotRadius;
    var endY = blockHeight - bottomPadding - dotRadius;
    if (endY < startY + minDotGap) endY = startY + minDotGap;

    final timeLabelHeight = 20.0;

    return Container(
      height: blockHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: separatorColor, width: 1),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Segment osi (cienka linia, wyśrodkowana w kolumnie B)
          Positioned(
            left: axisX - axisLineWidth / 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: axisLineWidth,
              color: axisColor,
            ),
          ),
          // Kropka start (na środku osi)
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
          // Czas startu: sam tekst, wyrównany do środka Y z kropką start
          Positioned(
            left: 0,
            top: startY - timeLabelHeight / 2,
            width: timeGutterWidth - timeToAxisGap,
            height: timeLabelHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatTime(entry.startAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: timeColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
          // Czas końca: sam tekst, wyrównany do środka Y z kropką end
          Positioned(
            left: 0,
            top: endY - timeLabelHeight / 2,
            width: timeGutterWidth - timeToAxisGap,
            height: timeLabelHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatTime(_effectiveEnd(entry)),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: timeColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
          // Tytuł (jeden pill, stały padding, jedna linia z ellipsis)
          Positioned(
            left: leftColumnsWidth + 12,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: titlePaddingH,
                    vertical: titlePaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: titleBg,
                    borderRadius: BorderRadius.circular(titleBorderRadius),
                  ),
                  child: Text(
                    entry.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatTime(DateTime dateTime) {
  return DateTimeUtils.formatTime(dateTime);
}
