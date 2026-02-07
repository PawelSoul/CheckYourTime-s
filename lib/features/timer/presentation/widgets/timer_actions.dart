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
    final softFilled = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      backgroundColor: Colors.white.withOpacity(0.08),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
    final softOutlined = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: Colors.white.withOpacity(0.15)),
      foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
    );

    if (isIdle) {
      buttons.add(
        FilledButton(
          style: softFilled,
          onPressed: onStart,
          child: const Text('Start'),
        ),
      );
    }

    if (isRunning) {
      buttons.addAll([
        FilledButton(
          style: softFilled,
          onPressed: onPause,
          child: const Text('Pause'),
        ),
        OutlinedButton(
          style: softOutlined,
          onPressed: onStop,
          child: const Text('Stop & Save'),
        ),
      ]);
    }

    if (isPaused) {
      buttons.addAll([
        FilledButton(
          style: softFilled,
          onPressed: onResume,
          child: const Text('Resume'),
        ),
        OutlinedButton(
          style: softOutlined,
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
