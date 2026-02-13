import 'package:flutter/material.dart';

import 'package:checkyourtime/core/utils/datetime_utils.dart';
import '../../domain/calendar_models.dart';

/// Minimalistyczna oś dnia: czas startu przy osi, kolorowy segment (długość = czas trwania), tytuł + zakres czasu.
class DayTimelineList extends StatelessWidget {
  const DayTimelineList({super.key, required this.tasks});

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
      itemBuilder: (context, index) => TimelineRow(entry: sorted[index]),
    );
  }
}

/// Jedna pozycja na osi: kolumna czasu | oś + segment | tytuł + subline.
class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.entry});

  final TimelineItemVm entry;

  static const _timeColumnWidth = 56.0;
  static const _axisColumnWidth = 24.0;
  static const _minRowHeight = 56.0;
  static const _maxRowHeight = 140.0;
  static const _axisLineWidth = 2.0;
  static const _segmentWidth = 8.0;
  static const _dotSize = 6.0;

  static double rowHeightForEntry(TimelineItemVm entry) {
    final durationMinutes = _durationMinutes(entry);
    return _clampDurationToHeight(durationMinutes);
  }

  static int _durationMinutes(TimelineItemVm entry) {
    if (entry.endAt != null) {
      final end = entry.endAt!;
      final start = entry.startAt;
      if (end.isBefore(start) || end.isAtSameMomentAs(start)) return 0;
      return end.difference(start).inMinutes;
    }
    final sec = entry.durationSec;
    if (sec <= 0) return 0;
    return sec ~/ 60;
  }

  static double _clampDurationToHeight(int durationMinutes) {
    if (durationMinutes <= 0) return _minRowHeight;
    const span = _maxRowHeight - _minRowHeight;
    final height = _minRowHeight + (durationMinutes / 60.0).clamp(0.0, 1.0) * span;
    return height.clamp(_minRowHeight, _maxRowHeight);
  }

  @override
  Widget build(BuildContext context) {
    final height = rowHeightForEntry(entry);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.6);
    final separatorColor = theme.dividerColor.withValues(alpha: 0.25);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: separatorColor, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateTimeUtils.formatTime(entry.startAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: muted,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: _axisColumnWidth,
            child: _AxisSegment(
              color: entry.categoryColor,
              lineWidth: _axisLineWidth,
              segmentWidth: _segmentWidth,
              dotSize: _dotSize,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _subline(TimelineItemVm entry) {
    final startStr = DateTimeUtils.formatTime(entry.startAt);
    if (entry.endAt == null) return '$startStr – …';
    return '$startStr – ${DateTimeUtils.formatTime(entry.endAt!)}';
  }
}

/// Kolumna B: cienka linia pionowa + kolorowy segment na wysokość wiersza + kropka u góry.
class _AxisSegment extends StatelessWidget {
  const _AxisSegment({
    required this.color,
    required this.lineWidth,
    required this.segmentWidth,
    required this.dotSize,
  });

  final Color color;
  final double lineWidth;
  final double segmentWidth;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return CustomPaint(
          size: Size(_AxisSegmentPainter.columnWidth, h),
          painter: _AxisSegmentPainter(
            color: color,
            lineWidth: lineWidth,
            segmentWidth: segmentWidth,
            dotSize: dotSize,
          ),
        );
      },
    );
  }
}

class _AxisSegmentPainter extends CustomPainter {
  _AxisSegmentPainter({
    required this.color,
    required this.lineWidth,
    required this.segmentWidth,
    required this.dotSize,
  });

  static const double columnWidth = 24.0;

  final Color color;
  final double lineWidth;
  final double segmentWidth;
  final double dotSize;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final h = size.height;

    // Linia pionowa (oś)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, h), linePaint);

    // Kolorowy segment (prostokąt na pełną wysokość wiersza)
    final segmentLeft = centerX - segmentWidth / 2;
    final segmentPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(segmentLeft, 0, segmentWidth, h),
        const Radius.circular(2),
      ),
      segmentPaint,
    );

    // Kropka u góry (początek segmentu)
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, dotSize), dotSize, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _AxisSegmentPainter old) =>
      old.color != color ||
      old.lineWidth != lineWidth ||
      old.segmentWidth != segmentWidth ||
      old.dotSize != dotSize;
}
