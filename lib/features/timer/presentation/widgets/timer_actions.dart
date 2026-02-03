import 'package:flutter/material.dart';

class TimerActions extends StatelessWidget {
  final bool isIdle;
  final bool isRunning;
  final bool isPaused;

  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const TimerActions({
    super.key,
    required this.isIdle,
    required this.isRunning,
    required this.isPaused,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (isIdle) {
      buttons.add(
        FilledButton(
          onPressed: onStart,
          child: const Text('Start'),
        ),
      );
    }

    if (isRunning) {
      buttons.addAll([
        FilledButton(
          onPressed: onPause,
          child: const Text('Pause'),
        ),
        OutlinedButton(
          onPressed: onStop,
          child: const Text('Stop & Save'),
        ),
      ]);
    }

    if (isPaused) {
      buttons.addAll([
        FilledButton(
          onPressed: onResume,
          child: const Text('Resume'),
        ),
        OutlinedButton(
          onPressed: onStop,
          child: const Text('Stop & Save'),
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: buttons,
      ),
    );
  }
}
