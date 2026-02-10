import 'package:flutter/material.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';

/// Pasek postępu godziny: 6 segmentów (po 10 min), wypełnienie w kolorze kategorii.
class SegmentedHourProgressBar extends StatelessWidget {
  const SegmentedHourProgressBar({
    super.key,
    required this.elapsed,
    this.categoryColorHex,
  });

  final Duration elapsed;
  final String? categoryColorHex;

  static const int _segmentCount = 6;
  static const int _secondsPerSegment = 600; // 10 min
  static const double _gap = 7;

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.parse(categoryColorHex);
    final progressInHour = (elapsed.inSeconds % 3600) / 3600.0;

    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Text(
            'Postęp godziny',
            style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              color: theme.colorScheme.surface.withOpacity(0.4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalGaps = _gap * (_segmentCount - 1);
                final segmentWidth =
                    (constraints.maxWidth - totalGaps) / _segmentCount;

                return Row(
                  children: List.generate(_segmentCount, (index) {
                    final segmentStart = index / _segmentCount;
                    final segmentEnd = (index + 1) / _segmentCount;
                    double fill;
                    if (progressInHour <= segmentStart) {
                      fill = 0;
                    } else if (progressInHour >= segmentEnd) {
                      fill = 1;
                    } else {
                      fill = (progressInHour - segmentStart) / (1 / _segmentCount);
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0) SizedBox(width: _gap),
                        _Segment(
                          width: segmentWidth,
                          fill: fill,
                          fillColor: color.withOpacity(0.85),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.width,
    required this.fill,
    required this.fillColor,
  });

  final double width;
  final double fill;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final fillWidth = width * fill.clamp(0.0, 1.0);
    return SizedBox(
      width: width,
      height: 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (fillWidth > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: fillWidth,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
