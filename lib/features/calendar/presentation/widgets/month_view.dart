import 'package:flutter/material.dart';

import '../../../../data/db/daos/sessions_dao.dart';
import '../../domain/calendar_models.dart';

class MonthView extends StatelessWidget {
  const MonthView({
    super.key,
    required this.month,
    required this.sessions,
    required this.dayDots,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<SessionWithTask> sessions;
  final Map<String, DayDotsVm> dayDots;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekdays = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];

  /// Dni miesiąca z sesjami (bez czasu – tylko data do porównania).
  static Set<DateTime> _daysWithSessions(List<SessionWithTask> sessions) {
    final set = <DateTime>{};
    for (final s in sessions) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.session.startAt);
      set.add(DateTime(d.year, d.month, d.day));
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    final daysWithSessions = _daysWithSessions(sessions);
    final year = month.year;
    final monthIndex = month.month;
    final first = DateTime(year, monthIndex, 1);
    final last = DateTime(year, monthIndex + 1, 0);
    final daysInMonth = last.day;
    final firstWeekday = first.weekday - 1;
    final padding = firstWeekday;
    final totalCells = padding + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final w in _weekdays)
              SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    w,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          ),
          children: [
            for (var r = 0; r < rows; r++)
              TableRow(
                children: [
                  for (var c = 0; c < 7; c++)
                    _DayCell(
                      dayIndex: r * 7 + c,
                      padding: padding,
                      daysInMonth: daysInMonth,
                      year: year,
                      monthIndex: monthIndex,
                      dayDots: dayDots,
                      hasSessions: (int day) {
                        if (day < 1 || day > daysInMonth) return false;
                        final d = DateTime(year, monthIndex, day);
                        return daysWithSessions.contains(d);
                      },
                      isSelected: (int day) {
                        if (day < 1 || day > daysInMonth) return false;
                        if (selectedDay == null) return false;
                        return selectedDay!.year == year &&
                            selectedDay!.month == monthIndex &&
                            selectedDay!.day == day;
                      },
                      onTap: (int day) {
                        if (day >= 1 && day <= daysInMonth) {
                          onDaySelected(DateTime(year, monthIndex, day));
                        }
                      },
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayIndex,
    required this.padding,
    required this.daysInMonth,
    required this.year,
    required this.monthIndex,
    required this.dayDots,
    required this.hasSessions,
    required this.isSelected,
    required this.onTap,
  });

  final int dayIndex;
  final int padding;
  final int daysInMonth;
  final int year;
  final int monthIndex;
  final Map<String, DayDotsVm> dayDots;
  final bool Function(int day) hasSessions;
  final bool Function(int day) isSelected;
  final void Function(int day) onTap;

  static const double _dotSize = 5;

  @override
  Widget build(BuildContext context) {
    final dayNumber = dayIndex - padding + 1;
    final isCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
    final day = dayNumber;
    final selected = isCurrentMonth && isSelected(day);
    final dotsVm = isCurrentMonth && day >= 1 && day <= daysInMonth
        ? dayDots[dateKey(DateTime(year, monthIndex, day))]
        : null;
    final hasDots = dotsVm != null && (dotsVm.colors.isNotEmpty || dotsVm.hasMore);

    return InkWell(
      onTap: isCurrentMonth ? () => onTap(day) : null,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isCurrentMonth ? '$day' : '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.bold : null,
                    color: isCurrentMonth
                        ? (selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
            if (hasDots) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < dotsVm!.colors.length; i++)
                    Container(
                      width: _dotSize,
                      height: _dotSize,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: dotsVm.colors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (dotsVm.hasMore)
                    Tooltip(
                      message: 'więcej',
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
