import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';
import '../application/timer_view_settings.dart';
import 'widgets/analog_stopwatch_view.dart';
import 'widgets/start_task_sheet.dart';
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: const TimerQuickToggle(),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }

  Future<void> _onStop(
    BuildContext context,
    TimerController controller,
  ) async {
    await controller.stop();
    if (!context.mounted) return;
    Future.microtask(() => controller.reset());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesja zapisana')),
      );
    }
  }
}
