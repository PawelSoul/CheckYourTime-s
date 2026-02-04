import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';
import 'widgets/start_task_sheet.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  static bool _isHandlingStop = false;

  static Future<void> _onStop(
    BuildContext context,
    WidgetRef ref,
    TimerController controller,
  ) async {
    if (_isHandlingStop) return;
    _isHandlingStop = true;
    try {
      final result = await controller.stop();
      if (!context.mounted || result == null) return;

      final name = await _showNameDialog(
        context,
        result.duration,
        result.taskId,
        controller,
      );
      if (!context.mounted) return;

      if (name != null && name.trim().isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesja zapisana. Pojawi się w kalendarzu.'),
          ),
        );
      }
    } finally {
      _isHandlingStop = false;
    }
  }

  static Future<String?> _showNameDialog(
    BuildContext context,
    Duration duration,
    String taskId,
    TimerController timerController,
  ) async {
    final textController = TextEditingController();
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          var alreadyPopped = false;
          void popWith(String? value) {
            if (alreadyPopped) return;
            alreadyPopped = true;
            Navigator.of(ctx).pop(value);
          }
          var isSaving = false;
          Future<void> saveAndPop() async {
            if (alreadyPopped || isSaving) return;
            isSaving = true;
            final name = textController.text.trim();
            if (name.isNotEmpty) {
              await timerController.setTaskName(taskId: taskId, name: name);
            }
            if (alreadyPopped) return;
            popWith(name.isEmpty ? null : name);
          }
          return AlertDialog(
            title: const Text('Nazwa zadania'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Czas sesji: $durationStr',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa',
                    hintText: 'np. Nauka / Gotowanie',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => saveAndPop(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => popWith(null),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => saveAndPop(),
                child: const Text('Zapisz'),
              ),
            ],
          );
        },
      );
    } finally {
      textController.dispose();
    }
  }

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
                      ? () => _onStop(context, ref, controller)
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
