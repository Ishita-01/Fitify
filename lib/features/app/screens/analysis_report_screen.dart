import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
    final labels = report.metrics.map((m) => m.label).toList();
    final values = report.metrics.map((m) => m.score).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Analysis Report', style: AppTextStyles.heading),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.ios_share_rounded,
                      size: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── OVERALL SCORE HERO ──────────────────────────────────────────
            DarkCard(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  // AI-detected exercise badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.15),
                          const Color(0xFFA855F7).withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 13, color: Color(0xFFA855F7)),
                        const SizedBox(width: 5),
                        Text('AI Detected',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFFA855F7),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            )),
                        Container(
                          width: 1,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 7),
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                        Icon(report.exercise.icon,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 5),
                        Text(report.exercise.label,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.accent,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_date(report.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 24),

                  // Big ring score
                  RingProgress(
                    value: report.overallScore / 100,
                    size: 160,
                    stroke: 14,
                    color: scoreColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${report.overallScore}',
                            style: AppTextStyles.display
                                .copyWith(fontSize: 52, color: scoreColor)),
                        Text('/ 100',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Grade badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_gradeIcon(report.overallScore),
                            size: 14, color: scoreColor),
                        const SizedBox(width: 6),
                        Text(_grade(report.overallScore),
                            style: AppTextStyles.label
                                .copyWith(color: scoreColor, fontSize: 13)),
                      ],
                    ),
                  ),

                  // Rep / hold stat badges
                  if (report.repCount != null || report.holdSeconds != null) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (report.repCount != null) ...[
                          _StatBadge(
                            icon: Icons.repeat_rounded,
                            label: '${report.repCount} Reps',
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (report.holdSeconds != null)
                          _StatBadge(
                            icon: Icons.timer_outlined,
                            label: '${report.holdSeconds}s Hold',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ── SKELETON OVERLAY VIDEO ──────────────────────────────────────
            if (report.overlayVideoPath != null) ...[
              _SectionLabel(
                title: 'Form Skeleton Overlay',
                subtitle: 'Pose tracking from your session',
                icon: Icons.animation_rounded,
              ),
              const SizedBox(height: 12),
              OverlayVideoPlayer(videoPath: report.overlayVideoPath!),
              const SizedBox(height: 26),
            ],

            // ── PERFORMANCE BREAKDOWN ───────────────────────────────────────
            _SectionLabel(
              title: 'Performance Breakdown',
              subtitle: 'Scored across 5 form dimensions',
              icon: Icons.analytics_rounded,
            ),
            const SizedBox(height: 12),

            // Row 1: Radar + Horizontal bars
            LayoutBuilder(
              builder: (context, constraints) {
                final halfW = (constraints.maxWidth - 12) / 2;
                return Column(
                  children: [
                    // TOP ROW: Radar | Metric Scores
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radar chart card
                        SizedBox(
                          width: halfW,
                          child: DarkCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.radar_rounded,
                                          size: 14, color: AppColors.accent),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Radar',
                                        style: AppTextStyles.label.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                RadarChart(
                                  labels: labels,
                                  values: values,
                                  size: halfW - 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Horizontal bars card
                        SizedBox(
                          width: halfW,
                          child: DarkCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.bar_chart_rounded,
                                          size: 14, color: AppColors.success),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Scores',
                                        style: AppTextStyles.label.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                HorizontalBarChart(
                                  labels: labels,
                                  values: values,
                                  height: halfW - 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // BOTTOM ROW: Ring gauge | Vertical bars
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Concentric rings card
                        SizedBox(
                          width: halfW,
                          child: DarkCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFA855F7).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.radio_button_checked_rounded,
                                          size: 14, color: Color(0xFFA855F7)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Ring Gauge',
                                        style: AppTextStyles.label.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: ConcentricRingsChart(
                                    labels: labels,
                                    values: values,
                                    size: halfW - 40,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Compact ring legend
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    for (var i = 0; i < labels.length; i++)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: ConcentricRingsChart.ringColors[
                                                  i % ConcentricRingsChart.ringColors.length],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(labels[i].split(' ').first,
                                              style: AppTextStyles.caption.copyWith(
                                                fontSize: 8,
                                                color: AppColors.textTertiary,
                                              )),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Vertical bars card
                        SizedBox(
                          width: halfW,
                          child: DarkCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.equalizer_rounded,
                                          size: 14, color: AppColors.warning),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Distribution',
                                        style: AppTextStyles.label.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                VerticalBarChart(
                                  labels: labels,
                                  values: values,
                                  height: halfW - 70,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Per-metric progress bars
            DarkCard(
              child: Column(
                children: [
                  for (var i = 0; i < report.metrics.length; i++) ...[
                    _MetricBar(metric: report.metrics[i]),
                    if (i < report.metrics.length - 1)
                      Divider(
                        height: 24,
                        color: AppColors.border,
                        thickness: 0.5,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ── IMPROVEMENT TREND ───────────────────────────────────────────
            _SectionLabel(
              title: 'Improvement Trend',
              subtitle: 'Last 5 sessions',
              icon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 12),
            DarkCard(
              child: SizedBox(
                height: 110,
                child: CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _TrendPainter(report.overallScore),
                ),
              ),
            ),
            const SizedBox(height: 26),

            // ── DETECTED ISSUES ─────────────────────────────────────────────
            _SectionLabel(
              title: 'Detected Issues',
              subtitle: 'Form problems flagged by AI',
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 12),
            for (final issue in report.issues) _IssueRow(issue: issue),
            const SizedBox(height: 10),

            // ── RECOMMENDATIONS ─────────────────────────────────────────────
            _SectionLabel(
              title: 'Recommendations',
              subtitle: 'What to work on next',
              icon: Icons.lightbulb_outline_rounded,
            ),
            const SizedBox(height: 12),
            DarkCard(
              child: Column(
                children: [
                  for (var i = 0; i < report.recommendations.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: AppColors.success, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(report.recommendations[i],
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary, fontSize: 14.5)),
                        ),
                      ],
                    ),
                    if (i < report.recommendations.length - 1)
                      Divider(
                        height: 22,
                        color: AppColors.border,
                        thickness: 0.5,
                      ),
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
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _grade(int s) {
    if (s >= 90) return 'Excellent form';
    if (s >= 80) return 'Great — minor tweaks';
    if (s >= 70) return 'Good — room to improve';
    return 'Needs work';
  }

  IconData _gradeIcon(int s) {
    if (s >= 90) return Icons.emoji_events_rounded;
    if (s >= 80) return Icons.thumb_up_rounded;
    if (s >= 70) return Icons.trending_up_rounded;
    return Icons.fitness_center_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section label with icon + subtitle
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title.copyWith(fontSize: 15.5)),
            const SizedBox(height: 1),
            Text(subtitle,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon + text stat badge (reps / hold duration)
// ─────────────────────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.label
                  .copyWith(color: AppColors.accent, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton overlay video player (in-app playback)
// ─────────────────────────────────────────────────────────────────────────────
class OverlayVideoPlayer extends StatefulWidget {
  final String videoPath;
  const OverlayVideoPlayer({super.key, required this.videoPath});

  @override
  State<OverlayVideoPlayer> createState() => _OverlayVideoPlayerState();
}

class _OverlayVideoPlayerState extends State<OverlayVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }).catchError((error) {
        if (!mounted) return;
        setState(() {
          _error = error.toString();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading skeleton video:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _controller.value.isPlaying ? 'Pause' : 'Play',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.accent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-metric progress bar row
// ─────────────────────────────────────────────────────────────────────────────
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
                      .copyWith(color: AppColors.textSecondary, fontSize: 13.5)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${metric.score}',
                  style: AppTextStyles.label
                      .copyWith(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: metric.score / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Issue row
// ─────────────────────────────────────────────────────────────────────────────
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
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: c, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(issue.title,
                  style: AppTextStyles.title.copyWith(fontSize: 14.5))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(issue.severity,
                style: AppTextStyles.caption
                    .copyWith(color: c, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trend line painter
// ─────────────────────────────────────────────────────────────────────────────
class _TrendPainter extends CustomPainter {
  _TrendPainter(this.latest);
  final int latest;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.6;

    // Horizontal grid lines
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
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

    // Gradient fill
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.22),
            AppColors.accent.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    // Line stroke
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.accent,
    );

    // Data point dots
    for (var i = 0; i < scores.length; i++) {
      final x = size.width * i / (scores.length - 1);
      final y = size.height * (1 - (scores[i] - 50) / 50).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x, y), i == scores.length - 1 ? 5 : 3,
          Paint()..color = AppColors.accent);
      if (i == scores.length - 1) {
        canvas.drawCircle(
          Offset(x, y),
          9,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
      }
    }
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
