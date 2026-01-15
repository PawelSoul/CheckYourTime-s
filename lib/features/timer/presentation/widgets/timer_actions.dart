import 'package:flutter/material.dart';
import '../../application/active_timer_controller.dart';

class TimerActions extends StatelessWidget {
  final TimerStatus status;
  final bool hasTaskName;

  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const TimerActions({
    super.key,
    required this.status,
    required this.hasTaskName,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (status == TimerStatus.idle) {
      buttons.add(
        FilledButton(
          onPressed: hasTaskName ? onStart : null,
          child: const Text('Start'),
        ),
      );
    }

    if (status == TimerStatus.running) {
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

    if (status == TimerStatus.paused) {
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
