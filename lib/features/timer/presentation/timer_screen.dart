import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';
import 'widgets/start_task_sheet.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Stoper')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _fmt(state.elapsed),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: state.activeSessionId == null
                      ? () => showStartTaskSheet(context, ref)
                      : null,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: (state.activeSessionId != null && state.isRunning)
                      ? controller.pause
                      : null,
                  child: const Text('Pauza'),
                ),
                ElevatedButton(
                  onPressed: (state.activeSessionId != null && !state.isRunning)
                      ? controller.resume
                      : null,
                  child: const Text('Wznów'),
                ),
                ElevatedButton(
                  onPressed: state.activeSessionId != null
                      ? () async {
                          final info = await controller.stop();
                          if (info == null) return;
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sesja zapisana. Pojawi się w kalendarzu.',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
