import 'package:flutter/material.dart';

/// Klucz dnia do grupowania (yyyy-mm-dd).
String dateKey(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Kropki na siatce dnia: max 3 kolory + flaga „więcej”.
class DayDotsVm {
  const DayDotsVm({required this.colors, this.hasMore = false});
  final List<Color> colors;
  final bool hasMore;
}

/// Element osi czasu (lista pod siatką – tryb „Oś czasu”).
class TimelineItemVm {
  const TimelineItemVm({
    required this.startAt,
    this.endAt,
    required this.title,
    required this.categoryColor,
    this.categoryName,
    required this.durationSec,
  });
  final DateTime startAt;
  final DateTime? endAt;
  final String title;
  final Color categoryColor;
  final String? categoryName;
  final int durationSec;
}

/// Grupa sesji wg kategorii (tryb „Według kategorii”).
class CategoryGroupVm {
  const CategoryGroupVm({
    this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.totalMinutes,
    required this.items,
  });
  final String? categoryId;
  final String categoryName;
  final Color categoryColor;
  final int totalMinutes;
  final List<TimelineItemVm> items;
}
