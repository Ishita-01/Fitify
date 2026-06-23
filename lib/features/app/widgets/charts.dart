import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A compact 7-day activity bar strip (Mon→Sun). `values` are 0..1 heights;
/// `todayIndex` (0..6) is highlighted.
class WeeklyBars extends StatelessWidget {
  const WeeklyBars({
    super.key,
    required this.values,
    required this.todayIndex,
    this.height = 70,
  });

  final List<double> values; // length 7
  final int todayIndex;
  final double height;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: values[i].clamp(0.06, 1.0)),
                    duration: Duration(milliseconds: 500 + i * 60),
                    curve: Curves.easeOut,
                    builder: (_, v, _) => Container(
                      width: 14,
                      height: height * v,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i == todayIndex
                              ? [const Color(0xFF3B82FF), AppColors.accent]
                              : [
                                  AppColors.accent.withValues(alpha: 0.35),
                                  AppColors.accent.withValues(alpha: 0.18),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_days[i],
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: i == todayIndex
                              ? AppColors.accent
                              : AppColors.textTertiary,
                          fontWeight: i == todayIndex
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular progress ring with a centered child (score / percent).
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value, // 0..1
    this.size = 96,
    this.stroke = 9,
    this.color,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color? color;
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
          painter: _RingPainter(v, stroke, color ?? AppColors.accent),
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
    this.color,
  });

  final List<String> labels;
  final List<int> values;
  final double size;
  final Color? color;

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
          painter: _RadarPainter(labels, values, color ?? AppColors.accent, t),
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
