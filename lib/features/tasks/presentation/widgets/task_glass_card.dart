import 'package:flutter/material.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import 'package:checkyourtime/core/utils/datetime_utils.dart';
import 'package:checkyourtime/core/widgets/glass_card.dart';
import '../../../../data/db/daos/tasks_dao.dart';
import '../task_details_page.dart';

/// Element listy zadań – karta glass, compact: tytuł + data/godzina, akcent kategorii.
class TaskGlassCard extends StatefulWidget {
  const TaskGlassCard({
    super.key,
    required this.task,
    this.categoryColorHex,
  });

  final TaskRow task;
  final String? categoryColorHex;

  @override
  State<TaskGlassCard> createState() => _TaskGlassCardState();
}

class _TaskGlassCardState extends State<TaskGlassCard> {
  @override
  Widget build(BuildContext context) {
    final colorHex = widget.categoryColorHex ?? widget.task.colorHex;
    final baseColor = CategoryColors.parse(colorHex);
    final accentColor = _accentColor(baseColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: _AnimatedTapCard(
        accentColor: accentColor,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => TaskDetailsPage(
                task: widget.task,
                categoryColorHex: widget.categoryColorHex,
              ),
            ),
          );
        },
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10, top: 5),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.task.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ) ??
                          const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  DateTimeUtils.formatTaskDateTimeFromEpochMs(widget.task.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ) ??
                      TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withSaturation((hsl.saturation * 0.6).clamp(0.0, 1.0)).toColor();
  }
}

/// Opakowuje kartę – animacja przy tap (150–200 ms).
class _AnimatedTapCard extends StatefulWidget {
  const _AnimatedTapCard({
    required this.child,
    required this.accentColor,
    required this.onTap,
  });

  final Widget child;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_AnimatedTapCard> createState() => _AnimatedTapCardState();
}

class _AnimatedTapCardState extends State<_AnimatedTapCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _isPressed ? 0.85 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _isPressed ? 0.98 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
