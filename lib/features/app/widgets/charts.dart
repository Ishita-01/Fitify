import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Circular progress ring with a centered child (score / percent).
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value, // 0..1
    this.size = 96,
    this.stroke = 9,
    this.color = AppColors.accent,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, stroke, color),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color);
  final double value;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceHighlight;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color.withValues(alpha: 0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

/// Radar / spider chart for the analysis metrics (each 0..100).
class RadarChart extends StatelessWidget {
  const RadarChart({
    super.key,
    required this.labels,
    required this.values, // 0..100 each, same length as labels
    this.size = 240,
    this.color = AppColors.accent,
  });

  final List<String> labels;
  final List<int> values;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, t, _) => CustomPaint(
          painter: _RadarPainter(labels, values, color, t),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.labels, this.values, this.color, this.t);
  final List<String> labels;
  final List<int> values;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.34;
    final n = values.length;
    final web = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.border;

    // Concentric rings.
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final a = -math.pi / 2 + 2 * math.pi * i / n;
        final p = center + Offset(r * math.cos(a), r * math.sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, web);
    }
    // Spokes + labels.
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final edge = center + Offset(radius * math.cos(a), radius * math.sin(a));
      canvas.drawLine(center, edge, web);
      tp.text = TextSpan(
          text: labels[i],
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textTertiary, fontSize: 10));
      tp.layout();
      final lp = center +
          Offset((radius + 16) * math.cos(a), (radius + 12) * math.sin(a));
      tp.paint(canvas, lp - Offset(tp.width / 2, tp.height / 2));
    }

    // Value polygon.
    final poly = Path();
    for (var i = 0; i <= n; i++) {
      final idx = i % n;
      final a = -math.pi / 2 + 2 * math.pi * idx / n;
      final r = radius * (values[idx] / 100) * t;
      final p = center + Offset(r * math.cos(a), r * math.sin(a));
      i == 0 ? poly.moveTo(p.dx, p.dy) : poly.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(poly, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
        poly,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * (values[i] / 100) * t;
      canvas.drawCircle(
          center + Offset(r * math.cos(a), r * math.sin(a)), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.t != t;
}
