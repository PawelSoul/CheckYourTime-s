import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import 'package:checkyourtime/features/tasks/application/task_notes_provider.dart';
import 'package:checkyourtime/providers/app_db_provider.dart';
import 'package:checkyourtime/data/db/daos/sessions_dao.dart';
import '../../application/alarm_provider.dart';
import '../../application/timer_controller.dart';

/// Warstwa kontrolek: jeden główny przycisk + szybkie akcje. Auto-hide po 5s.
class TimerControlLayer extends ConsumerStatefulWidget {
  const TimerControlLayer({
    super.key,
    required this.isIdle,
    required this.isRunning,
    required this.isPaused,
    required this.categoryColorHex,
    required this.categoryName,
    required this.currentElapsed,
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

  final bool isIdle;
  final bool isRunning;
  final bool isPaused;
  final String? categoryColorHex;
  final String categoryName;
  final Duration currentElapsed;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  /// Ustaw aktualny czas (np. gdy użytkownik zapomniał włączyć stoper).
  final void Function(Duration)? onEditTime;
  final VoidCallback onTapScreen;
  final String? activeSessionId;
  final String? activeTaskId;
  /// Wywoływane gdy widoczność kontrolek się zmienia (np. auto-hide lub wake).
  final void Function(bool visible)? onVisibilityChanged;

  @override
  ConsumerState<TimerControlLayer> createState() => TimerControlLayerState();
}

class TimerControlLayerState extends ConsumerState<TimerControlLayer> {
  bool _controlsVisible = true;
  Timer? _hideTimer;

  static const Duration _autoHideDuration = Duration(seconds: 5);
  static const Duration _animationDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDuration, () {
      if (!mounted) return;
      setState(() {
        _controlsVisible = false;
        widget.onVisibilityChanged?.call(false);
      });
    });
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() {
        _controlsVisible = true;
        widget.onVisibilityChanged?.call(true);
      });
    }
    _resetHideTimer();
  }

  /// Wywołane z zewnątrz (np. tap na ekran) – pokazuje kontrolki i resetuje timer auto-hide.
  void showControls() => _showControls();

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = CategoryColors.parse(widget.categoryColorHex);

    return IgnorePointer(
      ignoring: !_controlsVisible,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1 : 0,
        duration: _animationDuration,
        child: AnimatedSlide(
          offset: _controlsVisible ? Offset.zero : const Offset(0, 0.15),
          duration: _animationDuration,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QuickActionChip(
                  label: 'Alarm',
                  icon: Icons.alarm_outlined,
                  onTap: () {
                    widget.onTapScreen();
                    _showAlarmDialog(context);
                  },
                ),
                const SizedBox(width: 12),
                _QuickActionChip(
                  label: 'Notatka',
                  icon: Icons.note_add_outlined,
                  onTap: widget.isIdle
                      ? null
                      : () {
                          widget.onTapScreen();
                          _showNoteDialog(context);
                        },
                  tooltip: widget.isIdle ? 'Uruchom stoper, aby dodać notatkę' : null,
                ),
                if (!widget.isIdle && widget.onEditTime != null) ...[
                  const SizedBox(width: 12),
                  _QuickActionChip(
                    label: 'Edytuj czas',
                    icon: Icons.schedule_outlined,
                    onTap: () {
                      widget.onTapScreen();
                      _showEditTimeDialog(context);
                    },
                    tooltip: 'Ustaw czas (np. gdy zapomniałeś włączyć stoper)',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            if (widget.isIdle)
              _MainActionButton(
                label: 'Start',
                accentColor: accentColor,
                onTap: () {
                  widget.onTapScreen();
                  widget.onStart();
                },
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MainActionButton(
                    label: widget.isRunning ? 'Pauza' : 'Wznów',
                    accentColor: widget.isRunning
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                    onTap: () {
                      widget.onTapScreen();
                      if (widget.isRunning) {
                        widget.onPause();
                      } else {
                        widget.onResume();
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _MainActionButton(
                    label: 'Stop',
                    accentColor: Theme.of(context).colorScheme.error,
                    onTap: () {
                      widget.onTapScreen();
                      widget.onStop();
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
    );
  }

  void _showAlarmDialog(BuildContext context) {
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    showDialog<DateTime?>(
      context: context,
      builder: (ctx) => _AlarmDialog(),
    ).then((target) {
      if (!mounted) return;
      _resetHideTimer();
      if (target == null) return;
      ref.read(alarmTargetProvider.notifier).state = target;
      final delay = target.difference(DateTime.now());
      if (delay.isNegative || delay == Duration.zero) {
        ref.read(alarmTargetProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔔 Alarm!'), duration: Duration(seconds: 3)),
        );
        return;
      }
      Timer(delay, () {
        ref.read(alarmTargetProvider.notifier).state = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔔 Alarm!'), duration: Duration(seconds: 3)),
          );
        }
      });
    });
  }

  void _showNoteDialog(BuildContext context) {
    if (!mounted) return;
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    final taskId = widget.activeTaskId;
    showDialog<void>(
      context: context,
      builder: (ctx) => _NoteDialogContent(
        messenger: messenger,
        onSave: (String note) {
          if (taskId != null && note.trim().isNotEmpty) {
            ref.read(taskNotesProvider.notifier).addNote(taskId, note.trim());
          }
        },
      ),
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetHideTimer();
      });
    });
  }

  void _showEditTimeDialog(BuildContext context) {
    if (!mounted || widget.onEditTime == null) return;
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    final currentMinutes = widget.currentElapsed.inMinutes;
    showDialog<Duration>(
      context: context,
      builder: (ctx) => _EditTimeDialog(initialMinutes: currentMinutes),
    ).then((duration) {
      if (!mounted || duration == null) return;
      widget.onEditTime!(duration);
      _resetHideTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Czas ustawiony na ${duration.inMinutes} min',
          ),
        ),
      );
    });
  }
}

/// Dialog ustawiania czasu: godzina rozpoczęcia ↔ minuty (obustronna synchronizacja).
class _EditTimeDialog extends StatefulWidget {
  const _EditTimeDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_EditTimeDialog> createState() => _EditTimeDialogState();
}

class _EditTimeDialogState extends State<_EditTimeDialog> {
  late final TextEditingController _minutesController;
  DateTime? _startTime; // godzina rozpoczęcia (jeśli wybrana z pickera)

  @override
  void initState() {
    super.initState();
    final mins = widget.initialMinutes > 0 ? widget.initialMinutes : 30;
    _minutesController = TextEditingController(text: mins.toString());
    _startTime = DateTime.now().subtract(Duration(minutes: mins));
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  /// Minuty wyliczone z pola tekstowego (gdy użytkownik wpisuje minuty).
  int get _minutesFromField {
    final n = int.tryParse(_minutesController.text);
    return (n != null && n > 0) ? n : 0;
  }

  /// Aktualny „moment rozpoczęcia”: albo _startTime (z pickera), albo now - minuty z pola.
  DateTime get _computedStart {
    if (_startTime != null) return _startTime!;
    return DateTime.now().subtract(Duration(minutes: _minutesFromField));
  }

  /// Minuty „jak dawno temu” – z godziny rozpoczęcia lub z pola.
  int get _effectiveMinutes {
    if (_startTime != null) {
      final diff = DateTime.now().difference(_startTime!);
      return diff.inMinutes.clamp(1, 86400); // max ~1 dzień
    }
    return _minutesFromField;
  }

  void _syncFromMinutes() {
    setState(() => _startTime = null); // przy wpisywaniu minut traktuj jako „z minut”
  }

  void _syncFromStartTime(DateTime start) {
    setState(() {
      _startTime = start;
      final mins = DateTime.now().difference(start).inMinutes.clamp(1, 86400);
      _minutesController.text = mins.toString();
    });
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final now = DateTime.now();
    final initial = _computedStart;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null || !mounted) return;
    var start = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (start.isAfter(now)) start = start.subtract(const Duration(days: 1));
    _syncFromStartTime(start);
  }

  @override
  Widget build(BuildContext context) {
    final start = _computedStart;
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Ustaw czas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Minuty – ile minut temu rozpocząłeś (stoper będzie od tej wartości):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minuty',
                border: OutlineInputBorder(),
                hintText: 'np. 45',
                suffixText: 'min',
              ),
              onChanged: (_) => _syncFromMinutes(),
            ),
            const SizedBox(height: 8),
            Text(
              'Rozpoczęcie: $startStr',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Albo wybierz godzinę rozpoczęcia – minuty ustawią się automatycznie:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Godzina rozpoczęcia'),
              subtitle: Text(startStr),
              trailing: const Icon(Icons.access_time),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              onTap: () => _pickStartTime(context),
            ),
            const SizedBox(height: 4),
            Text(
              'To było ${_effectiveMinutes} min temu',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            final mins = _effectiveMinutes;
            if (mins > 0) {
              Navigator.of(context).pop(Duration(minutes: mins));
            }
          },
          child: const Text('Ustaw'),
        ),
      ],
    );
  }
}

/// Dialog notatki – controller i lifecycle tylko wewnątrz State, bez współdzielenia.
class _NoteDialogContent extends StatefulWidget {
  const _NoteDialogContent({
    required this.messenger,
    required this.onSave,
  });

  final ScaffoldMessengerState messenger;
  final void Function(String note) onSave;

  @override
  State<_NoteDialogContent> createState() => _NoteDialogContentState();
}

class _NoteDialogContentState extends State<_NoteDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAnuluj() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  void _onZapisz() {
    final note = _controller.text.trim();
    widget.onSave(note);
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Notatka zapisana')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notatka'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Opcjonalna notatka do sesji…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _onAnuluj,
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => _onZapisz(),
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}

class _AlarmDialog extends StatefulWidget {
  @override
  State<_AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<_AlarmDialog> {
  bool _useExactTime = false;
  TimeOfDay? _selectedTime;
  int? _selectedMinutes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alarm'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Za ile'),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Dokładna godzina'),
              ),
            ],
            selected: {_useExactTime},
            onSelectionChanged: (s) {
              setState(() => _useExactTime = s.first);
            },
          ),
          const SizedBox(height: 16),
          if (_useExactTime)
            ListTile(
              title: Text(_selectedTime == null
                  ? 'Wybierz godzinę'
                  : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );
                if (time != null) setState(() => _selectedTime = time);
              },
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mins in [5, 10, 15, 30, 60, 120])
                  ChoiceChip(
                    label: Text(mins < 60 ? '$mins min' : '${mins ~/ 60}h'),
                    selected: _selectedMinutes == mins,
                    onSelected: (s) => setState(() => _selectedMinutes = s ? mins : null),
                  ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            DateTime? target;
            if (_useExactTime && _selectedTime != null) {
              final now = DateTime.now();
              var alarmTime = DateTime(
                now.year,
                now.month,
                now.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              );
              if (alarmTime.isBefore(now)) {
                alarmTime = alarmTime.add(const Duration(days: 1));
              }
              target = alarmTime;
              Navigator.of(context).pop(target);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Alarm ustawiony na ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'),
                ),
              );
            } else if (!_useExactTime && _selectedMinutes != null) {
              target = DateTime.now().add(Duration(minutes: _selectedMinutes!));
              Navigator.of(context).pop(target);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Alarm ustawiony za $_selectedMinutes min'),
                ),
              );
            }
          },
          child: const Text('Ustaw'),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: chip);
    }
    return chip;
  }
}

class _MainActionButton extends StatelessWidget {
  const _MainActionButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: accentColor.withOpacity(0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}
