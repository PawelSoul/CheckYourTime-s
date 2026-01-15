import 'package:flutter/material.dart';

class TimerClock extends StatelessWidget {
  final Duration elapsed;

  const TimerClock({
    super.key,
    required this.elapsed,
  });

  String _two(int n) => n.toString().padLeft(2, '0');

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
    }
    return '${_two(minutes)}:${_two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final text = _format(elapsed);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
