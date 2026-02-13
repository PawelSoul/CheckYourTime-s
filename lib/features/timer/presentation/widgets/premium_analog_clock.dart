import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/constants/category_colors.dart';

// --- Stałe wizualne (ciemny motyw, lokalne) ---
const _dialCenterColor = Color(0xFF1E1E22);
const _dialEdgeColor = Color(0xFF0A0A0C);
const _outerRingOpacity = 0.09;
const _tickMinorOpacity = 0.14;
const _tickMajorOpacity = 0.32;
const _progressStrokeWidth = 3.5;
const _progressOpacity = 0.85;
const _handStrokeWidth = 3.2;
const _handOpacity = 0.92;
const _knobRadius = 5.0;
const _knobHighlightRadius = 2.0;
const _accentBlue = Color(0xFF0A84FF); // akcent w stylu iOS/Focus

/// Zegar analogowy w stylu premium (ciemna tarcza, delikatna głębia, pierścień postępu).
/// Wyświetla [elapsed] jako wskazówkę sekundową oraz opcjonalny pierścień postępu (np. w obrębie minuty).
class PremiumAnalogClock extends StatelessWidget {
  const PremiumAnalogClock({
    super.key,
    required this.elapsed,
    this.categoryColorHex,
    this.progress,
  });

  final Duration elapsed;
  /// Kolor kategorii dla pierścienia postępu; gdy null – używany jest akcent niebieski.
  final String? categoryColorHex;
  /// Postęp 0..1 (np. w obrębie minuty). Gdy null: (elapsed % 1 min) / 1 min.
  final double? progress;

  static double _progressFromElapsed(Duration elapsed) {
    final ms = elapsed.inMilliseconds % 60000;
    return ms / 60000.0;
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final h2 = h.toString().padLeft(2, '0');
    final m2 = m.toString().padLeft(2, '0');
    final s2 = s.toString().padLeft(2, '0');
    if (h > 0) return '$h2:$m2:$s2';
    return '$m2:$s2';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = progress ?? _progressFromElapsed(elapsed);
    final progressColor = _progressColor(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.hasBoundedWidth
                  ? constraints.maxWidth.clamp(0.0, 320.0)
                  : 280.0;
              final radius = side * 0.38;
              return SizedBox(
                width: side,
                height: side,
                child: CustomPaint(
                  painter: PremiumAnalogClockPainter(
                    elapsed: elapsed,
                    progress: effectiveProgress,
                    progressColor: progressColor,
                    textColor: textColor,
                  ),
                  size: Size(side, side),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _format(elapsed),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.9),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ) ??
                TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.9),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(BuildContext context) {
    if (categoryColorHex != null && categoryColorHex!.isNotEmpty) {
      return CategoryColors.parse(categoryColorHex).withOpacity(_progressOpacity);
    }
    return _accentBlue.withOpacity(_progressOpacity);
  }
}

class PremiumAnalogClockPainter extends CustomPainter {
  PremiumAnalogClockPainter({
    required this.elapsed,
    required this.progress,
    required this.progressColor,
    required this.textColor,
  });

  final Duration elapsed;
  final double progress;
  final Color progressColor;
  final Color textColor;

  static const double _twoPi = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;

    _drawDialBackground(canvas, center, radius);
    _drawOuterRing(canvas, center, radius);
    _drawMinuteTicks(canvas, center, radius);
    _drawProgressRing(canvas, center, radius);
    _drawHand(canvas, center, radius);
    _drawCenterKnob(canvas, center);
  }

  void _drawDialBackground(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [_dialCenterColor, _dialEdgeColor],
      );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = textColor.withOpacity(_outerRingOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 0.6, paint);
  }

  void _drawMinuteTicks(Canvas canvas, Offset center, double radius) {
    const outerInset = 4.0;
    const minorLength = 5.0;
    const majorLength = 11.0;
    final outerR = radius - outerInset;
    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * _twoPi - math.pi / 2;
      final isMajor = i % 5 == 0;
      final length = isMajor ? majorLength : minorLength;
      final innerR = outerR - length;
      final x1 = center.dx + innerR * math.cos(angle);
      final y1 = center.dy + innerR * math.sin(angle);
      final x2 = center.dx + outerR * math.cos(angle);
      final y2 = center.dy + outerR * math.sin(angle);
      final opacity = isMajor ? _tickMajorOpacity : _tickMinorOpacity;
      final paint = Paint()
        ..color = textColor.withOpacity(opacity)
        ..strokeWidth = isMajor ? 1.8 : 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  void _drawProgressRing(Canvas canvas, Offset center, double radius) {
    if (progress <= 0) return;
    final ringRadius = radius - 6;
    const startAngle = -math.pi / 2;
    final sweepAngle = progress * _twoPi;
    if (sweepAngle >= _twoPi) {
      final fullPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _progressStrokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, ringRadius, fullPaint);
      return;
    }
    // Opcjonalna delikatna „glow” – szerszy łuk z mniejszą nieprzezroczystością
    final glowPaint = Paint()
      ..color = progressColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _progressStrokeWidth + 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );
    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _progressStrokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  void _drawHand(Canvas canvas, Offset center, double radius) {
    final ms = elapsed.inMilliseconds % 60000;
    final angle = (ms / 60000.0) * _twoPi - math.pi / 2;
    final length = radius * 0.82;
    final end = Offset(
      center.dx + length * math.cos(angle),
      center.dy + length * math.sin(angle),
    );
    final paint = Paint()
      ..color = textColor.withOpacity(_handOpacity)
      ..strokeWidth = _handStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, end, paint);
  }

  void _drawCenterKnob(Canvas canvas, Offset center) {
    final fillPaint = Paint()
      ..color = textColor.withOpacity(0.28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _knobRadius, fillPaint);
    final highlightOffset = Offset(-_knobRadius * 0.4, -_knobRadius * 0.4);
    final highlightPaint = Paint()
      ..color = textColor.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + highlightOffset, _knobHighlightRadius, highlightPaint);
  }

  @override
  bool shouldRepaint(PremiumAnalogClockPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed ||
        oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.textColor != textColor;
  }
}
