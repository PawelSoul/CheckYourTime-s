import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';
import '../application/timer_view_settings.dart';
import '../../tasks/tasks_providers.dart';
import 'widgets/alarm_countdown_banner.dart';
import 'widgets/analog_stopwatch_view.dart';
import 'widgets/category_chip.dart';
import 'widgets/segmented_hour_progress_bar.dart';
import 'widgets/start_task_sheet.dart';
import 'widgets/timer_control_layer.dart';
import 'widgets/timer_clock.dart';
import 'widgets/timer_glow.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  final GlobalKey<TimerControlLayerState> _controlLayerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final viewSettings = ref.watch(timerViewSettingsProvider);
    final category = state.activeCategoryId != null
        ? ref.watch(categoryByIdProvider(state.activeCategoryId!))
        : null;

    final isIdle = state.activeSessionId == null;
    final isRunning = state.isRunning;
    final isPaused = state.activeSessionId != null && !state.isRunning;
    final categoryName = category?.name ?? 'Brak kategorii';
    final categoryColorHex = category?.colorHex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _controlLayerKey.currentState?.showControls(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              const AlarmCountdownBanner(),
              if (viewSettings.progressBarVisible) ...[
                const SizedBox(height: 12),
                SegmentedHourProgressBar(
                  elapsed: state.elapsed,
                  categoryColorHex: categoryColorHex,
                ),
              ],
              const SizedBox(height: 16),
              viewSettings.viewMode == TimerViewMode.analog
                  ? AnalogStopwatchView(elapsed: state.elapsed)
                  : TimerClock(elapsed: state.elapsed),
              if (state.activeCategoryId != null) ...[
                const SizedBox(height: 12),
                CategoryChip(
                  label: categoryName,
                  colorHex: categoryColorHex,
                ),
              ],
              const Spacer(),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  if (viewSettings.glowVisible)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 220,
                      child: TimerGlow(
                        isIdle: isIdle,
                        categoryColorHex: categoryColorHex,
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                        child: TimerControlLayer(
                          key: _controlLayerKey,
                          isIdle: isIdle,
                          isRunning: isRunning,
                          isPaused: isPaused,
                          categoryColorHex: categoryColorHex,
                          categoryName: categoryName,
                          onStart: () => showStartTaskSheet(context, ref),
                          onPause: () => controller.pause(),
                          onResume: () => controller.resume(),
                          onStop: () => _onStop(context, controller),
                          onTapScreen: () => _controlLayerKey.currentState?.showControls(),
                          activeSessionId: state.activeSessionId,
                          activeTaskId: state.activeTaskId,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
