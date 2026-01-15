import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/active_timer_controller.dart';
import 'widgets/timer_actions.dart';
import 'widgets/timer_clock.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeTimerControllerProvider);
    final controller = ref.read(activeTimerControllerProvider.notifier);

    final elapsed = state.session?.elapsed ?? Duration.zero;
    final taskName = state.session?.taskName ?? _taskController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        actions: [
          IconButton(
            tooltip: 'Reset (without saving)',
            onPressed: state.status == TimerStatus.idle ? null : controller.reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _taskController,
                enabled: state.status == TimerStatus.idle,
                decoration: const InputDecoration(
                  labelText: 'Task name',
                  hintText: 'e.g. Nauka / Gotowanie / Siłownia',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (taskName.isNotEmpty)
              Text(
                taskName,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Wpisz nazwę zadania, żeby wystartować',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            TimerClock(elapsed: elapsed),

            const Spacer(),

            TimerActions(
              status: state.status,
              hasTaskName: _taskController.text.trim().isNotEmpty,
              onStart: () {
                controller.start(taskName: _taskController.text);
              },
              onPause: controller.pause,
              onResume: controller.resume,
              onStop: () async {
                await controller.stopAndSave();
                // po zapisaniu czyścimy pole
                _taskController.clear();
                if (mounted) setState(() {});
                // (opcjonalnie) pokaż snackbar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session saved')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
