import 'package:flutter/material.dart';

import '../../../../data/db/daos/tasks_dao.dart';

/// Dialog edycji nazwy zadania – do użycia np. z ekranu szczegółów (logika edycji w przyszłości).
class EditTaskDialogContent extends StatefulWidget {
  const EditTaskDialogContent({super.key, required this.task});

  final TaskRow task;

  @override
  State<EditTaskDialogContent> createState() => _EditTaskDialogContentState();
}

class _EditTaskDialogContentState extends State<EditTaskDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nazwa zadania'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nazwa',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) {
          final trimmed = v.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            final v = _controller.text.trim();
            Navigator.of(context).pop(v.isEmpty ? null : v);
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}
