import 'package:flutter/material.dart';

class TimerClock extends StatelessWidget {
  const TimerClock({
    super.key,
    required this.elapsed,
    this.showMilliseconds = false,
  });

  final Duration elapsed;
  final bool showMilliseconds;

  String _two(int n) => n.toString().padLeft(2, '0');
  String _three(int n) => n.toString().padLeft(3, '0');

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final millis = d.inMilliseconds % 1000;
    final time = hours > 0
        ? '${_two(hours)}:${_two(minutes)}:${_two(seconds)}'
        : '${_two(minutes)}:${_two(seconds)}';
    if (showMilliseconds) {
      return '$time.${_three(millis)}';
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final text = _format(elapsed);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 58,
              fontWeight: FontWeight.w300,
              fontFeatures: const [FontFeature.tabularFigures()],
            ) ??
            const TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.w300,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
      ),
    );
  }
}
