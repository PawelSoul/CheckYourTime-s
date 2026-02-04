import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/timer_controller.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _askNameAndSave(BuildContext context, WidgetRef ref, String taskId) async {
    final controller = ref.read(timerControllerProvider.notifier);
    final textController = TextEditingController();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nazwa taska'),
          content: TextField(
            controller: textController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'np. Nauka, Siłownia...'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
              child: const Text('Zapisz'),
            ),
          ],
        ),
      );

      final cleaned = (name ?? '').trim();
      if (cleaned.isEmpty) return;

      await controller.setTaskName(taskId: taskId, name: cleaned);
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Zadanie zapisane. Pojawi się na liście i w kalendarzu.')),
      );
    } finally {
      textController.dispose();
    }
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
                  onPressed: state.activeSessionId == null ? controller.start : null,
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
                          await _askNameAndSave(context, ref, info.taskId);
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
