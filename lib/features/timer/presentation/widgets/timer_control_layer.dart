import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../application/timer_controller.dart';
import 'start_task_sheet.dart';

/// Warstwa kontrolek: jeden główny przycisk + szybkie akcje. Auto-hide po 5s.
class TimerControlLayer extends ConsumerStatefulWidget {
  const TimerControlLayer({
    super.key,
    required this.isIdle,
    required this.isRunning,
    required this.isPaused,
    required this.categoryColorHex,
    required this.categoryName,
    required this.onStart,
    required this.onPause,
    required this.onResume,
  required this.onStop,
  required this.onTapScreen,
  });

  final bool isIdle;
  final bool isRunning;
  final bool isPaused;
  final String? categoryColorHex;
  final String categoryName;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onTapScreen;

  @override
  ConsumerState<TimerControlLayer> createState() => _TimerControlLayerState();
}

class _TimerControlLayerState extends ConsumerState<TimerControlLayer> {
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
      setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
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

    return AnimatedOpacity(
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
                  label: 'Zmień kategorię',
                  icon: Icons.category_outlined,
                  onTap: () {
                    widget.onTapScreen();
                    _showCategorySheet(context);
                  },
                ),
                const SizedBox(width: 12),
                _QuickActionChip(
                  label: 'Notatka',
                  icon: Icons.note_add_outlined,
                  onTap: () {
                    widget.onTapScreen();
                    _showNoteSheet(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _MainActionButton(
                  isIdle: widget.isIdle,
                  isRunning: widget.isRunning,
                  isPaused: widget.isPaused,
                  accentColor: accentColor,
                  onStart: () {
                    widget.onTapScreen();
                    widget.onStart();
                  },
                  onPause: () {
                    widget.onTapScreen();
                    widget.onPause();
                  },
                  onResume: () {
                    widget.onTapScreen();
                    widget.onResume();
                  },
                  onStop: () {
                    widget.onTapScreen();
                    widget.onStop();
                  },
                ),
                if (!widget.isIdle)
                  Positioned(
                    right: -8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            widget.onTapScreen();
                            widget.onStop();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    showStartTaskSheet(context, ref, onTaskSelected: () {}).then((_) {
      if (mounted) _resetHideTimer();
    });
  }

  void _showNoteSheet(BuildContext context) {
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notatka'),
        content: TextField(
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Opcjonalna notatka do sesji…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) _resetHideTimer();
    });
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
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
    );
  }
}

class _MainActionButton extends StatelessWidget {
  const _MainActionButton({
    required this.isIdle,
    required this.isRunning,
    required this.isPaused,
    required this.accentColor,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final bool isIdle;
  final bool isRunning;
  final bool isPaused;
  final Color accentColor;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    String label;
    VoidCallback onTap;
    if (isIdle) {
      label = 'Start';
      onTap = onStart;
    } else if (isRunning) {
      label = 'Pauza';
      onTap = onPause;
    } else {
      label = 'Wznów';
      onTap = onResume;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: isIdle ? null : onStop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
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
    );
  }
}
