import 'package:flutter/material.dart';

import '../../../../data/db/daos/sessions_dao.dart';

class MonthView extends StatelessWidget {
  const MonthView({
    super.key,
    required this.month,
    required this.sessions,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<SessionWithTask> sessions;
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
    // Poniedziałek = 1, więc offset do pierwszego dnia (0 = Pn, 6 = Nd)
    final firstWeekday = first.weekday - 1;
    final padding = firstWeekday;
    final totalCells = padding + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nagłówki dni tygodnia
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
        // Siatka dni
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
    required this.hasSessions,
    required this.isSelected,
    required this.onTap,
  });

  final int dayIndex;
  final int padding;
  final int daysInMonth;
  final int year;
  final int monthIndex;
  final bool Function(int day) hasSessions;
  final bool Function(int day) isSelected;
  final void Function(int day) onTap;

  @override
  Widget build(BuildContext context) {
    final dayNumber = dayIndex - padding + 1;
    final isCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
    final day = dayNumber;
    final selected = isCurrentMonth && isSelected(day);
    final withSessions = isCurrentMonth && hasSessions(day);

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
            if (withSessions)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
