import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';
import '../application/timer_view_settings.dart';
import 'widgets/analog_stopwatch_view.dart';
import 'widgets/start_task_sheet.dart';
import 'widgets/sessions_timeline.dart';
import 'widgets/timer_actions.dart';
import 'widgets/timer_clock.dart';
import 'widgets/timer_quick_toggle.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final viewSettings = ref.watch(timerViewSettingsProvider);

    final isIdle = state.activeSessionId == null;
    final isRunning = state.isRunning;
    final isPaused = state.activeSessionId != null && !state.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const TimerQuickToggle(),
            const SizedBox(height: 4),
            Text(
              isIdle ? 'Naciśnij Start, żeby zacząć' : 'Sesja w toku',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            viewSettings.viewMode == TimerViewMode.analog
                ? AnalogStopwatchView(elapsed: state.elapsed)
                : TimerClock(elapsed: state.elapsed),
            const Spacer(),
            TimerActions(
              isIdle: isIdle,
              isRunning: isRunning,
              isPaused: isPaused,
              onStart: () => showStartTaskSheet(context, ref),
              onPause: () => controller.pause(),
              onResume: () => controller.resume(),
              onStop: () => _onStop(context, controller),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: const SessionsTimeline(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStop(
    BuildContext context,
    TimerController controller,
  ) async {
    final result = await controller.stop();
    if (!context.mounted || result == null) return;

    final name = await _showNameDialog(context, result.duration);
    if (!context.mounted) return;

    if (name != null && name.trim().isNotEmpty) {
      await controller.setTaskName(taskId: result.taskId, name: name.trim());
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesja zapisana')),
      );
    }
  }

  Future<String?> _showNameDialog(BuildContext context, Duration duration) async {
    final textController = TextEditingController();
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nazwa zadania'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Czas sesji: $durationStr', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nazwa',
                  hintText: 'np. Nauka / Gotowanie',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value.trim().isEmpty ? null : value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                final name = textController.text.trim();
                Navigator.of(context).pop(name.isEmpty ? null : name);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      );
    } finally {
      textController.dispose();
    }
  }
}
