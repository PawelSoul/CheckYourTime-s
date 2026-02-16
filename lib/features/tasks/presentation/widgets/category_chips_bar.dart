import 'package:flutter/material.dart';

import '../../../../core/constants/category_colors.dart';
import '../../../../data/db/daos/categories_dao.dart';

/// Poziomy przewijany pasek kategorii jako chipsy.
class CategoryChipsBar extends StatelessWidget {
  const CategoryChipsBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCategoryLongPress,
  });

  final List<CategoryRow> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<CategoryRow>? onCategoryLongPress;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryId == category.id;
          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category.id),
            onLongPress: onCategoryLongPress != null
                ? () => onCategoryLongPress!(category)
                : null,
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  final CategoryRow category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.parse(category.colorHex);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        splashColor: categoryColor.withOpacity(0.1),
        highlightColor: categoryColor.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withOpacity(0.15)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? categoryColor.withOpacity(0.6)
                  : theme.colorScheme.outline.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
