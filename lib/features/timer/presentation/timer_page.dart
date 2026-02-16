import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';
import '../application/timer_view_settings.dart';
import '../../tasks/tasks_providers.dart';
import 'widgets/alarm_countdown_banner.dart';
import 'widgets/analog_stopwatch_view.dart';
import 'widgets/premium_analog_clock.dart';
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
  bool _controlsVisible = true;

  void _wakeControls() {
    _controlLayerKey.currentState?.showControls();
  }

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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Główna zawartość – tap gdziekolwiek budzi kontrolki
            GestureDetector(
              onTap: _wakeControls,
              behavior: HitTestBehavior.translucent,
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
                  viewSettings.viewMode == TimerViewMode.analogPremium
                      ? PremiumAnalogClock(
                          elapsed: state.elapsed,
                          categoryColorHex: categoryColorHex,
                          progressRingVisible: viewSettings.premiumProgressRingVisible,
                          minuteHandVisible: viewSettings.analogMinuteHandVisible,
                          hourHandVisible: viewSettings.analogHourHandVisible,
                        )
                      : viewSettings.viewMode == TimerViewMode.analogClassic
                          ? AnalogStopwatchView(elapsed: state.elapsed)
                          : TimerClock(
                              elapsed: state.elapsed,
                              showMilliseconds: viewSettings.digitalMillisecondsVisible,
                            ),
                  if (state.activeCategoryId != null) ...[
                    const SizedBox(height: 12),
                    CategoryChip(
                      label: categoryName,
                      colorHex: categoryColorHex,
                    ),
                  ],
                  const Spacer(),
                  if (viewSettings.glowVisible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: SizedBox(
                        height: 110,
                        child: TimerGlow(
                          isIdle: isIdle,
                          categoryColorHex: categoryColorHex,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Kontrolki na dole (IgnorePointer gdy ukryte – w TimerControlLayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
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
                  onTapScreen: _wakeControls,
                  activeSessionId: state.activeSessionId,
                  activeTaskId: state.activeTaskId,
                  onVisibilityChanged: (visible) =>
                      setState(() => _controlsVisible = visible),
                ),
              ),
            ),
            // Pełnoekranowy overlay gdy kontrolki ukryte – tylko budzi, nie przekazuje tapu
            if (!_controlsVisible)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _wakeControls,
                  child: const ColoredBox(color: Colors.transparent),
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
