import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/timer_controller.dart';

/// Ekran do wpisania nazwy zadania po zatrzymaniu stopera.
/// Używany zamiast dialogu, żeby uniknąć błędu _dependents.isEmpty przy zamykaniu.
class NameTaskScreen extends ConsumerStatefulWidget {
  const NameTaskScreen({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<NameTaskScreen> createState() => _NameTaskScreenState();
}

class _NameTaskScreenState extends ConsumerState<NameTaskScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final timerNotifier = ref.read(timerControllerProvider.notifier);
    await timerNotifier.setTaskName(taskId: widget.taskId, name: name);
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nazwa zadania'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.pop(null),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nazwa',
                hintText: 'np. Nauka, Siłownia...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Zapisz'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : () => context.pop(null),
              child: const Text('Anuluj'),
            ),
          ],
        ),
      ),
    );
  }
}
