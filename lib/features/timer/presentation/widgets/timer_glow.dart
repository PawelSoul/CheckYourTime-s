import 'package:flutter/material.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';

/// Delikatna poświata nad paskiem postępu (w strefie przycisku Start).
/// Biała gdy zadanie nie rozpoczęte, w kolorze kategorii gdy sesja aktywna.
class TimerGlow extends StatelessWidget {
  const TimerGlow({
    super.key,
    required this.isIdle,
    this.categoryColorHex,
  });

  final bool isIdle;
  final String? categoryColorHex;

  @override
  Widget build(BuildContext context) {
    final color = isIdle
        ? Colors.white
        : CategoryColors.parse(categoryColorHex);

    return IgnorePointer(
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color.withOpacity(0.22),
              color.withOpacity(0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}
