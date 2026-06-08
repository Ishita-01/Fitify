import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/analysis.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts.dart';

/// The flagship: a premium, data-driven report for an uploaded workout video.
class AnalysisReportScreen extends StatelessWidget {
  const AnalysisReportScreen({super.key, required this.report});
  final AnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(report.overallScore);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22)),
                const SizedBox(width: 16),
                Text('Analysis Report', style: AppTextStyles.heading),
                const Spacer(),
                const Icon(Icons.ios_share_rounded,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 20),

            // Overall score hero.
            DarkCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(report.exercise.icon, size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(report.exercise.label, style: AppTextStyles.title),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_date(report.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 20),
                  RingProgress(
                    value: report.overallScore / 100,
                    size: 150,
                    stroke: 13,
                    color: scoreColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${report.overallScore}',
                            style: AppTextStyles.display
                                .copyWith(fontSize: 46, color: scoreColor)),
                        Text('/ 100',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_grade(report.overallScore),
                        style: AppTextStyles.label.copyWith(color: scoreColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Radar chart.
            Text('Performance Breakdown', style: AppTextStyles.heading),
            const SizedBox(height: 14),
            DarkCard(
              child: Center(
                child: RadarChart(
                  labels: report.metrics.map((m) => m.label).toList(),
                  values: report.metrics.map((m) => m.score).toList(),
                  size: 250,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Per-metric bars.
            DarkCard(
              child: Column(
                children: [
                  for (var i = 0; i < report.metrics.length; i++) ...[
                    _MetricBar(metric: report.metrics[i]),
                    if (i < report.metrics.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Improvement trend.
            Text('Improvement Trend', style: AppTextStyles.heading),
            const SizedBox(height: 14),
            DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last 5 sessions',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: _TrendPainter(report.overallScore),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Detected issues.
            Text('Detected Issues', style: AppTextStyles.heading),
            const SizedBox(height: 14),
            for (final issue in report.issues) _IssueRow(issue: issue),
            const SizedBox(height: 12),

            // Recommendations.
            Text('Recommendations', style: AppTextStyles.heading),
            const SizedBox(height: 14),
            DarkCard(
              child: Column(
                children: [
                  for (var i = 0; i < report.recommendations.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(report.recommendations[i],
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary, fontSize: 14.5)),
                        ),
                      ],
                    ),
                    if (i < report.recommendations.length - 1)
                      const Divider(height: 22),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _grade(int s) {
    if (s >= 90) return 'Excellent form';
    if (s >= 80) return 'Great — minor tweaks';
    if (s >= 70) return 'Good — room to improve';
    return 'Needs work';
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.metric});
  final MetricScore metric;

  @override
  Widget build(BuildContext context) {
    final c = _scoreColor(metric.score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(metric.label,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary))),
            Text('${metric.score}',
                style: AppTextStyles.label.copyWith(color: c)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: metric.score / 100),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ),
      ],
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});
  final DetectedIssue issue;

  @override
  Widget build(BuildContext context) {
    final c = _severityColor(issue.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: c, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(issue.title,
                  style: AppTextStyles.title.copyWith(fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(issue.severity,
                style: AppTextStyles.caption
                    .copyWith(color: c, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.latest);
  final int latest;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.6;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final scores = [62, 68, 71, 78, latest];
    final path = Path();
    final fill = Path();
    for (var i = 0; i < scores.length; i++) {
      final x = size.width * i / (scores.length - 1);
      final y = size.height * (1 - (scores[i] - 50) / 50).clamp(0.0, 1.0);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x332563FF), Color(0x002563FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.accent);
    final lastX = size.width;
    final lastY = size.height * (1 - (scores.last - 50) / 50).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _scoreColor(int s) {
  if (s >= 85) return AppColors.success;
  if (s >= 70) return AppColors.warning;
  return AppColors.danger;
}

Color _severityColor(String sev) {
  switch (sev) {
    case 'major':
      return AppColors.danger;
    case 'moderate':
      return AppColors.warning;
    default:
      return AppColors.textSecondary;
  }
}
