import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/timer_view_settings.dart';

class AnalogStopwatchPainter extends CustomPainter {
  AnalogStopwatchPainter({
    required this.elapsed,
    required this.minuteHandVisible,
    required this.hourHandVisible,
    required this.numbersStyle,
    required this.numbersVisible,
    required this.textColor,
  });

  final Duration elapsed;
  final bool minuteHandVisible;
  final bool hourHandVisible;
  final AnalogNumbersStyle numbersStyle;
  final bool numbersVisible;
  final Color textColor;

  static const double _twoPi = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    _drawBackgroundRing(canvas, center, radius);
    _drawMinuteTicks(canvas, center, radius);
    if (numbersVisible) _drawNumbers(canvas, center, radius);
    _drawHub(canvas, center);
    _drawHands(canvas, center, radius);
  }

  void _drawBackgroundRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, paint);
  }

  void _drawMinuteTicks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      if (i % 5 == 0) continue;
      final angle = _tickToRadians(i);
      final innerR = radius - 8;
      final outerR = radius - 4;
      final x1 = center.dx + innerR * math.sin(angle);
      final y1 = center.dy - innerR * math.cos(angle);
      final x2 = center.dx + outerR * math.sin(angle);
      final y2 = center.dy - outerR * math.cos(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  void _drawNumbers(Canvas canvas, Offset center, double radius) {
    final fontSize = numbersStyle == AnalogNumbersStyle.large ? 14.0 : 11.0;
    final opacity = numbersStyle == AnalogNumbersStyle.large ? 0.9 : 0.5;
    final numberRadius = radius - 22;
    for (var i = 1; i <= 12; i++) {
      final angle = _hourToRadians(i);
      final x = center.dx + numberRadius * math.sin(angle);
      final y = center.dy - numberRadius * math.cos(angle);
      _drawText(canvas, i.toString(), Offset(x, y), fontSize, opacity);
    }
  }

  void _drawText(Canvas canvas, String text, Offset at, double fontSize, [double opacity = 0.85]) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor.withOpacity(opacity),
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(at.dx - tp.width / 2, at.dy - tp.height / 2),
    );
  }

  void _drawHub(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, paint);
  }

  void _drawHands(Canvas canvas, Offset center, double radius) {
    final elapsedMs = elapsed.inMilliseconds;

    if (hourHandVisible) {
      final hoursMs = elapsedMs % (12 * 3600 * 1000);
      final hoursAngle = (hoursMs / (12 * 3600 * 1000)) * _twoPi - math.pi / 2;
      _drawHand(
        canvas,
        center,
        radius * 0.40,
        hoursAngle,
        4,
        Colors.white.withOpacity(0.9),
      );
    }

    if (minuteHandVisible) {
      final minutesMs = elapsedMs % (60 * 60 * 1000);
      final minutesAngle = (minutesMs / (60 * 60 * 1000)) * _twoPi - math.pi / 2;
      _drawHand(
        canvas,
        center,
        radius * 0.65,
        minutesAngle,
        3,
        Colors.white.withOpacity(0.85),
      );
    }

    final secondsMs = elapsedMs % (60 * 1000);
    final secondsAngle = (secondsMs / (60 * 1000)) * _twoPi - math.pi / 2;
    _drawHand(
      canvas,
      center,
      radius * 0.88,
      secondsAngle,
      2,
      Colors.white.withOpacity(0.95),
    );
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double length,
    double angleRad,
    double width,
    Color color,
  ) {
    final end = Offset(
      center.dx + length * math.cos(angleRad),
      center.dy + length * math.sin(angleRad),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, end, paint);
  }

  double _tickToRadians(int tick) {
    return (tick / 60) * _twoPi - math.pi / 2;
  }

  /// 12 u góry, 3 po prawej, 6 na dole, 9 po lewej (jak na prawdziwym zegarze).
  double _hourToRadians(int hour) {
    final h = hour == 12 ? 0 : hour;
    return (h / 12) * _twoPi;
  }

  @override
  bool shouldRepaint(AnalogStopwatchPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed ||
        oldDelegate.minuteHandVisible != minuteHandVisible ||
        oldDelegate.hourHandVisible != hourHandVisible ||
        oldDelegate.numbersStyle != numbersStyle ||
        oldDelegate.numbersVisible != numbersVisible ||
        oldDelegate.textColor != textColor;
  }
}
