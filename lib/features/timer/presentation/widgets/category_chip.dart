import 'package:flutter/material.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';

/// Chip z kropką koloru kategorii + nazwa (glass, iOS-soft).
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.colorHex,
  });

  final String label;
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.parse(colorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}
