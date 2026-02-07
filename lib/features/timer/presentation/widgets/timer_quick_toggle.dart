import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timer_view_settings.dart';

class TimerQuickToggle extends ConsumerWidget {
  const TimerQuickToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(timerViewSettingsProvider);
    final notifier = ref.read(timerViewSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _Segment(
                    label: 'Cyfrowy',
                    icon: Icons.schedule,
                    isSelected: settings.viewMode == TimerViewMode.digital,
                    onTap: () => notifier.setViewMode(TimerViewMode.digital),
                  ),
                  _Segment(
                    label: 'Analogowy',
                    icon: Icons.access_time,
                    isSelected: settings.viewMode == TimerViewMode.analog,
                    onTap: () => notifier.setViewMode(TimerViewMode.analog),
                  ),
                ],
              ),
            ),
          ),
          if (settings.viewMode == TimerViewMode.analog) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAnalogSettingsSheet(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _showAnalogSettingsSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timerViewSettingsProvider.notifier);
    final current = ref.read(timerViewSettingsProvider).analogHandsMode;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Wskazówki analogowe',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('2 (min + sek)'),
                subtitle: const Text('Tylko minutowa i sekundowa'),
                leading: Radio<AnalogHandsMode>(
                  value: AnalogHandsMode.two,
                  groupValue: current,
                  onChanged: (v) {
                    if (v != null) notifier.setAnalogHandsMode(v);
                    Navigator.of(ctx).pop();
                  },
                ),
                onTap: () {
                  notifier.setAnalogHandsMode(AnalogHandsMode.two);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                title: const Text('3 (godz + min + sek)'),
                subtitle: const Text('Godzinowa, minutowa i sekundowa'),
                leading: Radio<AnalogHandsMode>(
                  value: AnalogHandsMode.three,
                  groupValue: current,
                  onChanged: (v) {
                    if (v != null) notifier.setAnalogHandsMode(v);
                    Navigator.of(ctx).pop();
                  },
                ),
                onTap: () {
                  notifier.setAnalogHandsMode(AnalogHandsMode.three);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
