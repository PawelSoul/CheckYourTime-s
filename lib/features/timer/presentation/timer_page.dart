import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';
import '../application/timer_view_settings.dart';
import '../../tasks/tasks_providers.dart';
import 'widgets/alarm_countdown_banner.dart';
import 'widgets/analog_stopwatch_view.dart';
import 'widgets/premium_analog_clock.dart';
import 'widgets/category_chip.dart';
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

  /// Meta bez elapsed – ogranicza przebudowy przy ticku (200 ms).
  static (String? a, bool r, String? c, String? t) _meta(TimerState s) =>
      (s.activeSessionId, s.isRunning, s.activeCategoryId, s.activeTaskId);

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(timerControllerProvider.select(_meta));
    final controller = ref.read(timerControllerProvider.notifier);
    final viewSettings = ref.watch(timerViewSettingsProvider);
    final category =
        meta.$3 != null ? ref.watch(categoryByIdProvider(meta.$3!)) : null;

    final isIdle = meta.$1 == null;
    final isRunning = meta.$2;
    final isPaused = meta.$1 != null && !meta.$2;
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
            GestureDetector(
              onTap: _wakeControls,
              behavior: HitTestBehavior.translucent,
              child: Column(
                children: [
                  const AlarmCountdownBanner(),
                  Consumer(
                    builder: (context, ref, _) {
                      final state = ref.watch(timerControllerProvider);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          viewSettings.viewMode == TimerViewMode.analogPremium
                              ? PremiumAnalogClock(
                                  elapsed: state.elapsed,
                                  categoryColorHex: categoryColorHex,
                                  progressRingVisible:
                                      viewSettings.premiumProgressRingVisible,
                                  minuteHandVisible:
                                      viewSettings.analogMinuteHandVisible,
                                  hourHandVisible:
                                      viewSettings.analogHourHandVisible,
                                )
                              : viewSettings.viewMode ==
                                      TimerViewMode.analogClassic
                                  ? AnalogStopwatchView(elapsed: state.elapsed)
                                  : TimerClock(
                                      elapsed: state.elapsed,
                                      showMilliseconds: viewSettings
                                          .digitalMillisecondsVisible,
                                    ),
                        ],
                      );
                    },
                  ),
                  if (meta.$3 != null && !_controlsVisible) ...[
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                child: _TimerControlLayerWithElapsed(
                  controlKey: _controlLayerKey,
                  isIdle: isIdle,
                  isRunning: isRunning,
                  isPaused: isPaused,
                  categoryColorHex: categoryColorHex,
                  categoryName: categoryName,
                  onStart: () => showStartTaskSheet(context, ref),
                  onPause: () => controller.pause(),
                  onResume: () => controller.resume(),
                  onStop: () => _onStop(context, controller),
                  onEditTime: (d) => controller.setElapsed(d),
                  onTapScreen: _wakeControls,
                  activeSessionId: meta.$1,
                  activeTaskId: meta.$4,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zatrzymać stoper?'),
        content: const Text('Czy na pewno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tak'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
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

/// Kontrolki z currentElapsed z wewnętrznego watch – tylko ten widget rebuilduje przy ticku.
class _TimerControlLayerWithElapsed extends ConsumerWidget {
  const _TimerControlLayerWithElapsed({
    required this.controlKey,
    required this.isIdle,
    required this.isRunning,
    required this.isPaused,
    required this.categoryColorHex,
    required this.categoryName,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    this.onEditTime,
    required this.onTapScreen,
    required this.activeSessionId,
    required this.activeTaskId,
    this.onVisibilityChanged,
  });

  final GlobalKey<TimerControlLayerState> controlKey;
  final bool isIdle;
  final bool isRunning;
  final bool isPaused;
  final String? categoryColorHex;
  final String categoryName;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final void Function(Duration)? onEditTime;
  final VoidCallback onTapScreen;
  final String? activeSessionId;
  final String? activeTaskId;
  final void Function(bool)? onVisibilityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentElapsed =
        ref.watch(timerControllerProvider.select((s) => s.elapsed));
    return TimerControlLayer(
      key: controlKey,
      isIdle: isIdle,
      isRunning: isRunning,
      isPaused: isPaused,
      categoryColorHex: categoryColorHex,
      categoryName: categoryName,
      currentElapsed: currentElapsed,
      onStart: onStart,
      onPause: onPause,
      onResume: onResume,
      onStop: onStop,
      onEditTime: onEditTime,
      onTapScreen: onTapScreen,
      activeSessionId: activeSessionId,
      activeTaskId: activeTaskId,
      onVisibilityChanged: onVisibilityChanged,
    );
  }
}
