import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_view_settings.dart';
import 'analog_stopwatch_painter.dart';

class AnalogStopwatchView extends ConsumerWidget {
  const AnalogStopwatchView({
    super.key,
    required this.elapsed,
  });

  final Duration elapsed;

  static const double _size = 260;

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final h2 = h.toString().padLeft(2, '0');
    final m2 = m.toString().padLeft(2, '0');
    final s2 = s.toString().padLeft(2, '0');
    return '$h2:$m2:$s2';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(timerViewSettingsProvider);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: CustomPaint(
              painter: AnalogStopwatchPainter(
                elapsed: elapsed,
                handsMode: settings.analogHandsMode,
                textColor: textColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _format(elapsed),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
