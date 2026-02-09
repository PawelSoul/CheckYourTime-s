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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      child: Row(
        children: [
          Icon(
            Icons.alarm,
            size: 20,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _remaining.isNegative || _remaining == Duration.zero
                  ? 'Alarm za 0:00'
                  : 'Alarm za ${_formatDuration(_remaining)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  ),
            ),
          ),
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
      ),
    );
  }
}
