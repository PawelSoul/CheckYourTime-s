import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import 'package:checkyourtime/core/widgets/glass_card.dart';
import '../../../../data/db/daos/categories_dao.dart';

/// Element listy kategorii w stylu glass – kropka w kolorze kategorii + nazwa.
class CategoryGlassTile extends StatelessWidget {
  const CategoryGlassTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  final CategoryRow category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static const double _radius = 15;
  static const double _dotSize = 15;
  static const Duration _transitionDuration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.parse(category.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(_radius),
          splashColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.03),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: GlassStyle.blurSigma,
                sigmaY: GlassStyle.blurSigma,
              ),
              child: AnimatedContainer(
                duration: _transitionDuration,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  color: Colors.white.withOpacity(isSelected ? 0.055 : 0.045),
                  border: Border.all(
                    color: Colors.white.withOpacity(isSelected ? 0.12 : 0.08),
                    width: GlassStyle.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.15),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.name.isEmpty ? '?' : category.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                            ) ??
                            TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
