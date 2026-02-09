import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/widgets/glass_card.dart';
import '../../application/alarm_provider.dart';

/// Małe okienko pod przełącznikiem Cyfrowy/Analogowy z odliczaniem do alarmu.
class AlarmCountdownBanner extends ConsumerWidget {
  const AlarmCountdownBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(alarmTargetProvider);

    if (target == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _AlarmCountdownContent(
        target: target,
        onCancel: () => ref.read(alarmTargetProvider.notifier).state = null,
      ),
    );
  }
}

class _AlarmCountdownContent extends StatefulWidget {
  const _AlarmCountdownContent({
    required this.target,
    required this.onCancel,
  });

  final DateTime target;
  final VoidCallback onCancel;

  @override
  State<_AlarmCountdownContent> createState() => _AlarmCountdownContentState();
}

class _AlarmCountdownContentState extends State<_AlarmCountdownContent> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (widget.target.isBefore(now) || widget.target.isAtSameMomentAs(now)) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    setState(() => _remaining = widget.target.difference(now));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatDuration(Duration d) {
    final totalSec = d.inSeconds;
    if (totalSec >= 3600) {
      final h = totalSec ~/ 3600;
      final m = (totalSec % 3600) ~/ 60;
      final s = totalSec % 60;
      return '${h}h ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isTapped = true);
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 14,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _remaining.isNegative || _remaining == Duration.zero
                  ? '0:00'
                  : _formatDuration(_remaining),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (_isTapped) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onCancel,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
