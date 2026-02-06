import 'dart:ui';

import 'package:flutter/material.dart';

/// Stałe stylu glass – jeden punkt definicji (blur, grubość obramowania).
class GlassStyle {
  GlassStyle._();
  static const double blurSigma = 12;
  static const double borderWidth = 1;
}

/// Uniwersalny kontener w stylu glassmorphism – tło, obramowanie, blur.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.borderRadius = 18,
    this.backgroundOpacity = 0.04,
    this.borderOpacity = 0.08,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  /// Opacity tła (0.04 = domyślne karty zadań; 0.045–0.06 = kategorie).
  final double backgroundOpacity;
  /// Opacity obramowania (0.08 = domyślne; 0.12 = wybrana kategoria).
  final double borderOpacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassStyle.blurSigma,
          sigmaY: GlassStyle.blurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(backgroundOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: GlassStyle.borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }
    return content;
  }
}
